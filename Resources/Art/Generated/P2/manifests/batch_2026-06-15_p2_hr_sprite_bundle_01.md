# batch_2026-06-15_p2_hr_sprite_bundle_01

Status: completed

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Generated resources:
- `char_hr_sprite_bundle`

Pipeline:
- `$generate2dsprite`
- `asset_type`: `character`
- `bundle`: `hero_action_bundle`
- `view`: `side`
- `art_style`: `clean_hd`
- `reference`: none; generated directly from section 5.24 identity prompt, then used accepted idle sheet as the action reference
- `engine_target`: project-native Godot resource folders

Deliverables:
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/idle/raw-sheet.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/idle/processed/sheet-transparent.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/idle/processed/animation.gif`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/run/raw-sheet.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/run/processed/sheet-transparent.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/run/processed/animation.gif`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/execute_cast/raw-sheet.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/execute_cast/processed/sheet-transparent.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/execute_cast/processed/animation.gif`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/hurt/raw-sheet.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/hurt/processed/sheet-transparent.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/hurt/processed/animation.gif`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/char_hr_sprite_bundle_contact_sheet_v1.png`
- `Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1/char_hr_sprite_bundle_validation_v1.json`

Validation summary:
- Per-action sheets were generated separately, not as a mixed action atlas.
- Background rule: raw sheets use solid `#FF00FF` magenta, with chroma cleanup accepted.
- Processor settings: `component_mode=largest`, `align=feet`, `shared_scale=true`, `fit_scale=0.78`.
- Accepted actions: `idle`, `run`, `execute_cast`, `hurt`.
- `edge_touch_frames`: empty for all actions.
- Output body heights stay in the `93-99px` range across all accepted frames.
- The first hurt generation was rejected for cell-edge contact; the accepted hurt sheet is the regenerated safer-margin version.
- Giant paper storms, paperwork walls, detached red effect clouds, horror styling, projectiles, and long trails were excluded from body sheets.
