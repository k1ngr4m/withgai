import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const root = process.cwd();
const enemyConfigPath = path.join(root, "Data", "Generated", "Config", "EnemyDef.json");
const enemies = JSON.parse(fs.readFileSync(enemyConfigPath, "utf8"));
const frameWidth = 300;
const frameHeight = 260;

const actionFrames = {
  idle: [
    { scale: 0.92, rotate: 0, dx: 0, dy: 1 },
    { scale: 0.94, rotate: 0, dx: 0, dy: -1 },
    { scale: 0.92, rotate: 0, dx: 0, dy: 1 },
    { scale: 0.91, rotate: 0, dx: 0, dy: 2 },
  ],
  attack: [
    { scale: 0.92, rotate: -2, dx: -3, dy: 1 },
    { scale: 1.00, rotate: 3, dx: 7, dy: -2 },
    { scale: 0.97, rotate: 1, dx: 4, dy: 0 },
    { scale: 0.92, rotate: 0, dx: 0, dy: 1 },
  ],
  hurt: [
    { scale: 0.92, rotate: 0, dx: 0, dy: 1, tint: false },
    { scale: 0.90, rotate: -4, dx: -7, dy: 2, tint: true },
    { scale: 0.91, rotate: 3, dx: 5, dy: 1, tint: true },
    { scale: 0.92, rotate: 0, dx: 0, dy: 1, tint: false },
  ],
};

function projectPath(resPath) {
  if (!resPath.startsWith("res://")) {
    throw new Error(`Expected res:// path, got ${resPath}`);
  }
  return path.join(root, resPath.slice("res://".length));
}

function runMagick(args) {
  execFileSync("magick", args, { stdio: "pipe" });
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function frameSizeFor(enemyId) {
  if (enemyId.startsWith("boss_")) return 250;
  if (enemyId.startsWith("elite_")) return 240;
  return 230;
}

function makeFrame(input, output, size, transform) {
  const resized = Math.max(64, Math.round(size * transform.scale));
  const args = [
    "-size", `${frameWidth}x${frameHeight}`,
    "xc:none",
    "(",
    input,
    "-auto-orient",
    "-resize", `${resized}x${resized}`,
  ];
  if (transform.rotate !== 0) {
    args.push("-background", "none", "-rotate", String(transform.rotate));
  }
  if (transform.tint) {
    args.push("-fill", "#ff5a66", "-colorize", "18");
  }
  args.push(
    ")",
    "-gravity", "center",
    "-geometry", `${transform.dx >= 0 ? "+" : ""}${transform.dx}${transform.dy >= 0 ? "+" : ""}${transform.dy}`,
    "-composite",
    output,
  );
  runMagick(args);
}

function makeSheet(framePaths, background, output) {
  runMagick([
    "-size", `${frameWidth * 2}x${frameHeight * 2}`,
    `xc:${background}`,
    "(", framePaths[0], ")",
    "-gravity", "NorthWest",
    "-geometry", "+0+0",
    "-composite",
    "(", framePaths[1], ")",
    "-gravity", "NorthEast",
    "-geometry", "+0+0",
    "-composite",
    "(", framePaths[2], ")",
    "-gravity", "SouthWest",
    "-geometry", "+0+0",
    "-composite",
    "(", framePaths[3], ")",
    "-gravity", "SouthEast",
    "-geometry", "+0+0",
    "-composite",
    output,
  ]);
}

function makeGif(framePaths, output) {
  runMagick(["-delay", "16", "-loop", "0", ...framePaths, output]);
}

for (const enemy of enemies) {
  const input = projectPath(enemy.art_path);
  if (!fs.existsSync(input)) {
    throw new Error(`Missing enemy art source for ${enemy.id}: ${enemy.art_path}`);
  }
  for (const [action, transforms] of Object.entries(actionFrames)) {
    const actionRoot = path.join(root, "Resources", "Art", "Generated", "P0", "enemies", `${enemy.id}_anim_v1`, action);
    const processed = path.join(actionRoot, "processed");
    ensureDir(processed);
    const framePaths = transforms.map((transform, index) => {
      const frame = path.join(processed, `${action}-${index + 1}.png`);
      makeFrame(input, frame, frameSizeFor(enemy.id), transform);
      return frame;
    });
    makeSheet(framePaths, "#FF00FF", path.join(actionRoot, "raw-sheet.png"));
    fs.copyFileSync(path.join(actionRoot, "raw-sheet.png"), path.join(processed, "raw-sheet.png"));
    fs.copyFileSync(path.join(actionRoot, "raw-sheet.png"), path.join(processed, "raw-sheet-clean.png"));
    makeSheet(framePaths, "none", path.join(processed, "sheet-transparent.png"));
    makeGif(framePaths, path.join(processed, "animation.gif"));
    const prompt = [
      `${enemy.id} ${action} 2x2 sprite sheet`,
      `Source art: ${enemy.art_path}`,
      "Derived first-pass combat motion frames from existing AI-generated enemy art.",
    ].join("\n");
    fs.writeFileSync(path.join(processed, "prompt-used.txt"), `${prompt}\n`);
    fs.writeFileSync(path.join(actionRoot, "prompt-used.txt"), `${prompt}\n`);
    fs.writeFileSync(path.join(processed, "pipeline-meta.json"), `${JSON.stringify({
      target: "creature",
      mode: action,
      prompt,
      input: enemy.art_path,
      rows: 2,
      cols: 2,
      frame_labels: framePaths.map((_, index) => `${action}-${index + 1}`),
      frames: framePaths.map((frame, index) => ({
        frame: index + 1,
        path: path.relative(root, frame),
        transform: transforms[index],
        output_size: [frameWidth, frameHeight],
        edge_touch: false,
      })),
      edge_touch_frames: [],
    }, null, 2)}\n`);
  }
}

console.log(`Built ${enemies.length} enemy animation bundles.`);
