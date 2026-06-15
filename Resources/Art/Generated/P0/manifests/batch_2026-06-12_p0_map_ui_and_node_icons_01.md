# P0 Batch Manifest 2026-06-12

## Batch Scope
- Batch ID: `2026-06-12_p0_map_ui_and_node_icons_01`
- Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)
- Goal:
  - 楼层导航背景
  - 奖励页背景
  - 休息处背景
  - 商店背景
  - 节点图标 `node_icon_combat_set`
- Generation mode:
  - Built-in `image_gen`
  - `node_icon_combat_set` 使用 `$generate2dsprite` 约束编写 prompt，并用本地处理脚本完成拆帧与透明化

## Output Files

### Backgrounds
- [bg_map_floor_navigation_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/bg_map_floor_navigation_v1.png)
- [ui_reward_bg_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/ui_reward_bg_v1.png)
- [bg_rest_break_room_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/bg_rest_break_room_v1.png)
- [bg_shop_vending_machine_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/bg_shop_vending_machine_v1.png)

### Node Icon Pack
- Raw sheet:
  - [raw-sheet.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/raw-sheet.png)
- Processed:
  - [raw-sheet-clean.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/raw-sheet-clean.png)
  - [sheet-transparent.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-transparent.png)
  - [sheet-1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-1.png)
  - [sheet-2.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-2.png)
  - [sheet-3.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-3.png)
  - [sheet-4.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-4.png)
  - [sheet-5.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-5.png)
  - [sheet-6.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-6.png)
  - [sheet-7.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-7.png)
  - [sheet-8.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-8.png)
  - [sheet-9.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-9.png)
  - [animation.gif](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/animation.gif)
  - [pipeline-meta.json](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/pipeline-meta.json)

## Prompt Records

### `bg_map_floor_navigation_v1`
```text
Use case: stylized-concept
Asset type: map scene background for a workplace roguelike card game
Primary request: create the floor navigation and tree-map background from the project asset prompt manual
Scene/backdrop: a semi-top-down view of a high-rise office building turned into a corporate floor navigation poster, with visible floors, corridors, meeting rooms, cubicles, glass elevator shafts, and directional path logic, but not a technical blueprint
Subject: no node icons, no text, no UI elements; this is a clean background base for a map screen
Composition: wide 16:9 horizontal background, strong central vertical structure, clear left and right negative space for path overlays and node markers, readable architectural hierarchy, balanced emptiness for UI layering
Style: clear 2D commercial UI background, polished 2D card-game art, modern office building, promotion-path feeling, corporate systems atmosphere, readable shapes, not over-detailed, not blueprint-only
Color and lighting: cold white, gray-blue, tiny accents of warning orange, clean corporate lighting
Mood: career climb, office labyrinth, structured but absurd workplace progression
Constraints: no text labels, no fantasy tower, no watermark, no unreadable architectural clutter, no built-in map nodes
```

### `ui_reward_bg_v1`
```text
Use case: stylized-concept
Asset type: reward screen background for a workplace roguelike card game
Primary request: create the reward screen background from the project asset prompt manual
Scene/backdrop: a clean office reward-selection tabletop scene inside a corporate environment, with orderly card candidates, relic trays, performance-point light chips, reflected cold-white office surfaces, and a rational post-battle selection atmosphere
Subject: no characters, no text, no UI widgets; this is a reward screen background only
Composition: wide 16:9 horizontal background, central and lower safe area reserved for three-card choice and reward panel, restrained desk staging, clean negative space around the focal tray area
Style: clear 2D commercial card-game UI background, polished 2D game art, modern office card roguelike atmosphere, readable surfaces, not treasure-room fantasy, not casino reward spectacle
Color and lighting: cold white office light, gray-blue corporate palette, subtle reflective highlights, calm accent lights
Mood: post-battle evaluation, rational upgrade choice, office professionalism with absurd game logic
Constraints: no treasure chest, no cluttered desk mess, no text, no watermark, no characters
```

### `bg_rest_break_room_v1`
```text
Use case: stylized-concept
Asset type: rest-area background for a workplace roguelike card game
Primary request: create the break room rest background following the project asset prompt manual and generate2dmap baked_scene_mode guidance
Scene/backdrop: a clean office break room with coffee machine, water dispenser, fridge, snacks, disposable cups, casual chairs, and subtle signs of exhausted office life, inside a pressured office building but temporarily safe
Subject: no characters, no UI, no text; this is a flat scene background only
Composition: wide 16:9 horizontal background, readable central rest zone, enough empty space for rest UI overlay, comforting but still clearly office-themed
Style: clean HD 2D commercial game background, polished 2D art, readable composition, absurd workplace satire, not cozy home kitchen, not horror restroom
Color and lighting: bright cold-white office lighting softened slightly, gray-blue base, warm coffee-machine highlights and small comfort accents
Mood: brief relief, temporary recovery, still inside the machine
Constraints: no text labels, no clutter overload, no characters, no watermark
```

### `bg_shop_vending_machine_v1`
```text
Use case: stylized-concept
Asset type: shop background for a workplace roguelike card game
Primary request: create the office vending-machine shop background following the project asset prompt manual and generate2dmap baked_scene_mode guidance
Scene/backdrop: an office vending-machine corridor with bright vending machines, convenience shelves, corporate hallway depth, product glow, and a slight late-night illicit purchase feeling inside a modern office tower
Subject: no characters, no UI, no text; this is a flat shop background only
Composition: wide 16:9 horizontal background, readable central shopping zone, enough clear space for shop UI overlays, clean corridor staging, strong focal area around the vending machine cluster
Style: clean HD 2D commercial game background, polished 2D card-game art, workplace satire, not a street convenience store, not cyberpunk alley, not horror darkness
Color and lighting: cold corporate hallway lighting with bright product glow, gray-blue base, subtle saturated vending highlights
Mood: questionable after-hours spending, secret power-up shopping in office purgatory
Constraints: no text labels, no characters, no watermark, no clutter overload
```

### `node_icon_combat_set_v1`
```text
Use case: stylized-concept
Asset type: icon-style sprite sheet for a workplace roguelike card game map nodes
Primary request: create a clean_hd 3x3 icon-style prop sheet for the node icon set
Scene/backdrop: none, this is a solid-magenta asset sheet only
Subject: nine equal cells in an exact 3x3 grid, each cell containing one centered symbolic office-themed node icon: normal battle, elite battle, shop vending machine, rest break room, random event envelope, boss office seal, reward card, locked path marker, and one intentionally empty magenta cell
Composition: exact 3x3 sprite sheet, every icon single-object silhouette, centered with generous padding, consistent scale, high contrast, clean commercial 2D game UI icon style
Style: clean HD icon pack, polished 2D game asset style, crisp edges, readable at small sizes, workplace fantasy satire through office symbols, not realistic scenes
Technical constraints: solid #FF00FF flat background only, no gradients in background, no text, no labels, no borders, no visible grid lines, no UI panels, no characters, exact grid count only, every icon fully inside its cell, same icon scale family across cells
```

## Sprite Processing Command
```bash
python3 /Users/linyiming/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process \
  --input /Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/raw-sheet.png \
  --target asset \
  --mode sheet \
  --rows 3 \
  --cols 3 \
  --cell-size 418 \
  --output-dir /Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed \
  --fit-scale 0.92 \
  --align center \
  --shared-scale \
  --component-mode largest \
  --component-padding 8 \
  --min-component-area 200 \
  --threshold 100 \
  --edge-threshold 150 \
  --edge-clean-depth 2
```

## Notes
- This batch establishes the first reusable `$generate2dsprite` icon pipeline in the project.
- Next recommended batch:
  - `ui_battle_frame_style`
  - `ui_resource_panel_backend`
  - `ui_resource_panel_frontend`
  - `ui_resource_panel_tester`
  - `ui_resource_panel_algorithm`
  - `ui_resource_panel_product_manager`
