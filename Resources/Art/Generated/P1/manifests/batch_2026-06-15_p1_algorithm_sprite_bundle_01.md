# batch_2026-06-15_p1_algorithm_sprite_bundle_01

Status: completed

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Generated resources:
- `char_algorithm_sprite_bundle`

Pipeline:
- `$generate2dsprite`
- `asset_type`: `character`
- `bundle`: `hero_action_bundle`
- `view`: `side`
- `art_style`: `clean_hd`
- `reference`: `Resources/Art/Generated/P0/characters/char_algorithm_keyart_v1.png`
- `engine_target`: project-native Godot resource folders

Deliverables:
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/idle/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/idle/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/idle/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/run/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/run/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/run/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/charge/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/charge/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/charge/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/cast/raw-sheet.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/cast/processed/sheet-transparent.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/cast/processed/animation.gif`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/char_algorithm_sprite_bundle_contact_sheet_v1.png`
- `Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1/char_algorithm_sprite_bundle_validation_v1.json`

Validation summary:
- Per-action sheets were generated separately, not as a mixed action atlas.
- Background rule: raw sheets use solid `#FF00FF` magenta, with chroma cleanup accepted.
- Processor settings: `component_mode=largest`, `align=feet`, `shared_scale=true`, `fit_scale=0.78`.
- Accepted actions: `idle`, `run`, `charge`, `cast`.
- `edge_touch_frames`: empty for all actions.
- Output body heights stay in the `94-99px` range across all accepted frames.
- Giant magic circles, matrix grid panels, detached cube swarms, projectiles, and long trails were excluded from body sheets.
