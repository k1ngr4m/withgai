# batch_2026-06-15_p0_enemy_baseline_01

Status: generated_processed

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Planned resources:
- enemy_slacker_coworker
- enemy_workaholic_coworker
- enemy_angry_cleaner
- enemy_salesman
- elite_airdrop_project_lead
- enemy_portrait_icon_set

Generation mode:
- Built-in image generation for the visible enemy portraits and boss-like unit art.
- `$generate2dsprite` for the enemy portrait icon set if packed as a sheet.

Suggested order:
1. `enemy_slacker_coworker`
2. `enemy_workaholic_coworker`
3. `enemy_angry_cleaner`
4. `enemy_salesman`
5. `elite_airdrop_project_lead`
6. `enemy_portrait_icon_set`

Prompt summary:
- Ordinary enemies should remain readable office-worker distortions, not fantasy monsters.
- The elite enemy should feel more structured, pressurized, and visually dominant than the ordinary enemies.
- The portrait icon set should stay small, readable, and high-contrast for battle UI use.

Recommended output folders:
- Resources/Art/Generated/P0/enemies/enemy_slacker_coworker_v1/
- Resources/Art/Generated/P0/enemies/enemy_workaholic_coworker_v1/
- Resources/Art/Generated/P0/enemies/enemy_angry_cleaner_v1/
- Resources/Art/Generated/P0/enemies/enemy_salesman_v1/
- Resources/Art/Generated/P0/enemies/elite_airdrop_project_lead_v1/
- Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/

## Prompt Records

### `enemy_slacker_coworker_v1`

```text
Create the P0 enemy key art for "摸鱼同事" / slacker coworker, a semi-realistic polished 2D commercial card-game enemy illustration for a workplace roguelike. A modern office employee lounges or leans near a cubicle workstation, lazy but sly expression, phone browsing, snacks, office partition pieces, and improvised desk clutter forming a small defensive barrier. The image should communicate "sometimes does not attack, but slows the rhythm." Bright open-office background simplified, subject clear, absurd workplace comedy tone, readable silhouette, suitable for later portrait crop. No text, no watermark, no logo.
```

Negative prompt:

```text
avoid zombie look, avoid exaggerated monster claws, avoid horror tone, avoid photorealism, avoid chibi proportions, avoid cluttered unreadable office
```

### `enemy_workaholic_coworker_v1`

```text
Create the P0 enemy key art for "卷王同事" / workaholic coworker, a semi-realistic polished 2D commercial card-game enemy illustration for a workplace roguelike. A modern internet-company employee with over-caffeinated eyes and frantic fast movement, carrying a laptop bag and several devices, typing rapidly or handling many tickets at once. Office supplies and task cards fly like combo weapons around the subject, clearly communicating fast multi-hit attacks. Bright office environment, absurd but readable, strong motion, clear silhouette, suitable for later portrait crop. No text, no watermark, no logo.
```

Negative prompt:

```text
avoid superhero costume, avoid cyber ninja, avoid horror mutation overload, avoid photorealism, avoid unreadable device clutter
```

### `enemy_angry_cleaner_v1`

```text
Create the P0 enemy key art for "暴躁保洁阿姨" / angry cleaner, a semi-realistic polished 2D commercial card-game enemy illustration for a workplace roguelike. A strong office cleaner in cleaning uniform, holding mop, bucket, and spray bottle like heavy improvised weapons. Fierce authoritative expression, not a horror monster. Wet floor streaks and cleaning tools create a heavy single-hit attack feeling. Office-building corridor background, subject clear, strong readable posture, suitable for later portrait crop. No text, no watermark, no logo.
```

Negative prompt:

```text
avoid demon janitor, avoid gore, avoid slapstick cartoon proportions, avoid horror tone, avoid fantasy weapon redesign
```

### `enemy_salesman_v1`

```text
Create the P0 enemy key art for "西装推销员" / salesman, a semi-realistic polished 2D commercial card-game enemy illustration for a workplace roguelike. A pushy office salesman in an exaggerated fitted suit, enthusiastically handing out package proposals, contracts, and sales-talk cards. Low-value pollution-card papers and contracts float around him, making the pressure come from office sales material rather than magic. Modern office lobby or office area background, energetic but oppressive pose, clear subject, suitable for later portrait crop. No readable text, no watermark, no logo.
```

Negative prompt:

```text
avoid mafia look, avoid gun, avoid horror salesman grin, avoid readable contract text, avoid photorealism
```

### `elite_airdrop_project_lead_v1`

```text
Create the P0 elite enemy key art for "空降项目组长" / airdrop project lead, a semi-realistic polished 2D commercial card-game elite enemy illustration for a workplace roguelike. A modern middle-management project coordinator with stronger presence than ordinary enemies. Around the subject float deadline countdowns, project timeline bars, urgent red project frames, and waterfall task charts, all stylized without readable text. The pose should feel pressuring, like a huge burst is approaching. Office project war-room background, elite enemy mass and authority, clear silhouette, suitable for later portrait crop. No text, no watermark, no logo.
```

Negative prompt:

```text
avoid generic office worker, avoid final boss scale, avoid sci-fi commander, avoid readable UI text, avoid cluttered dashboard wall
```

### `enemy_portrait_icon_set_v1`

```text
Use $generate2dsprite to create a clean_hd 4x4 portrait-icon pack for a workplace roguelike card game enemy roster. Include centered head-and-shoulder portraits for slacker coworker, workaholic coworker, angry cleaner, salesman, process specialist, performance inspector, meeting maniac, airdrop director, compliance judge, airdrop project lead, outsource manager, budget gatekeeper, approval eye, pitch supervisor, mutant HR, and mutant CEO. Solid #FF00FF background, exact 4x4 grid, one portrait per cell, high contrast, readable at small size, absurd office satire style, no text, no labels, no borders, no visible guide marks.
```

Processing note:

```bash
python3 /Users/linyiming/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process \
  --input Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/raw-sheet.png \
  --target asset \
  --mode sheet \
  --rows 4 \
  --cols 4 \
  --fit-scale 0.90 \
  --align center \
  --shared-scale \
  --component-mode largest
```

Validation checklist after generation:
- Each individual enemy key art exists in its target folder with prompt metadata.
- `enemy_portrait_icon_set_v1` has raw, cleaned, transparent sheet, 16 extracted frames, and `pipeline-meta.json`.
- Icon pack frames are head-and-shoulder portraits, readable at small size, and do not contain full-body figures or busy backgrounds.

## Generated Outputs

Enemy key art:
- `Resources/Art/Generated/P0/enemies/enemy_slacker_coworker_v1/raw.png`
- `Resources/Art/Generated/P0/enemies/enemy_workaholic_coworker_v1/raw.png`
- `Resources/Art/Generated/P0/enemies/enemy_angry_cleaner_v1/raw.png`
- `Resources/Art/Generated/P0/enemies/enemy_salesman_v1/raw.png`
- `Resources/Art/Generated/P0/enemies/elite_airdrop_project_lead_v1/raw.png`

Enemy key art QA:
- `Resources/Art/Generated/P0/enemies/enemy_baseline_contact_sheet_v1.png`
- `Resources/Art/Generated/P0/enemies/enemy_baseline_validation_v1.json`

Enemy portrait icon set:
- `Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/raw-sheet-retry.png`
- `Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/raw-sheet-selected-1024.png`
- `Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/sheet-transparent-final.png`
- `Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/enemy_portrait_final-1.png` through `enemy_portrait_final-16.png`
- `Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/enemy_portrait_icon_set_final_contact_sheet_v1.png`
- `Resources/Art/Generated/P0/icons/enemy_portrait_icon_set_v1/enemy_portrait_icon_set_final_validation_v1.json`

Validation notes:
- All five enemy key art files are `1024x1536` RGB PNGs with prompt metadata and API response metadata.
- The final portrait icon sheet is `1024x1024` RGBA with 16 transparent `256x256` cells and no edge-alpha frames.
- The first portrait sheet attempt was kept as raw provenance. The retry sheet was selected because it better matched the office-satire enemy identity.
- The final icon sheet uses deterministic crop windows from the generated retry sheet because the generated grid spacing was visually correct but not mathematically equal.
