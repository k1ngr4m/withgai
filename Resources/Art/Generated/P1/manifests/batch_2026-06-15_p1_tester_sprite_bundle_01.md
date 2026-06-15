# batch_2026-06-15_p1_tester_sprite_bundle_01

Status: completed

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Generated resources:
- `char_tester_sprite_bundle`

Pipeline:
- `$generate2dsprite`
- `asset_type`: `character`
- `bundle`: `hero_action_bundle`
- `view`: `side`
- `art_style`: `clean_hd`
- `reference`: `Resources/Art/Generated/P0/characters/char_tester_keyart_v1.png`
- `engine_target`: project-native Godot resource folders

Deliverables:
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/idle/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/idle/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/idle/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/run/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/run/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/run/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/debuff_cast/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/debuff_cast/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/debuff_cast/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/hurt/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/hurt/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/hurt/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/char_tester_sprite_bundle_contact_sheet_v1.png`
- `Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1/char_tester_sprite_bundle_validation_v1.json`

Validation summary:
- Per-action sheets were generated separately, not as a mixed action atlas.
- Background rule: raw sheets use solid `#FF00FF` magenta, with chroma cleanup accepted.
- Processor settings: `component_mode=largest`, `align=feet`, `shared_scale=true`, `fit_scale=0.78`.
- Accepted actions: `idle`, `run`, `debuff_cast`, `hurt`.
- `edge_touch_frames`: empty for all actions.
- Output body heights stay in the `94-99px` range across all accepted frames.
- Detached large VFX, giant warning symbols, checklist panels, projectiles, and glitch clouds were excluded from body sheets.
