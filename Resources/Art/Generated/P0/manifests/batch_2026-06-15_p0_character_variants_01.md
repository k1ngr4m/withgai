# batch_2026-06-15_p0_character_variants_01

Status: generated_processed

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Planned resources:
- char_backend_bust
- char_backend_head_icon
- char_frontend_bust
- char_frontend_head_icon
- char_tester_bust
- char_tester_head_icon
- char_algorithm_bust
- char_algorithm_head_icon
- char_product_manager_bust
- char_product_manager_head_icon

Generation mode:
- Built-in image generation for all visible portrait assets.
- Use `$generate2dsprite` only if a portrait is packed as a sheet, which is not preferred here.

Recommended output folders:
- Resources/Art/Generated/P0/characters/char_backend_bust_v1/
- Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/
- Resources/Art/Generated/P0/characters/char_frontend_bust_v1/
- Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/
- Resources/Art/Generated/P0/characters/char_tester_bust_v1/
- Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/
- Resources/Art/Generated/P0/characters/char_algorithm_bust_v1/
- Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/
- Resources/Art/Generated/P0/characters/char_product_manager_bust_v1/
- Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/

Prompt summary:
- `char_backend_bust`: calm defensive posture, dark gray-blue hoodie or programmer jacket, cache/service motifs, preserve the backend engineer identity from `char_backend_keyart_v1`.
- `char_backend_head_icon`: front or 3/4 face, cool gray-blue palette, minimal service-node or cache marker, preserve backend identity and calm expression.
- `char_frontend_bust`: agile expressive posture, layered stylish clothing, component/style motifs, preserve the frontend engineer identity from `char_frontend_keyart_v1`.
- `char_frontend_head_icon`: front or 3/4 face, bright blue/white/teal palette, minimal module or UI motif, preserve frontend identity.
- `char_tester_bust`: sharp observational pose, QA/checklist/log tablet cues, red/yellow/green alert language, preserve tester identity from `char_tester_keyart_v1`.
- `char_tester_head_icon`: focused face, strict QA expression, compact alert motif, preserve tester identity.
- `char_algorithm_bust`: severe analytical pose, cool blue and deep gray palette, matrix/pathfinding/computation cues, preserve algorithm identity from `char_algorithm_keyart_v1`.
- `char_algorithm_head_icon`: focused face, high-compute cool palette, minimal geometry cue, preserve algorithm identity.
- `char_product_manager_bust`: confident controlling posture, business-casual styling, roadmap/priority motifs, preserve product manager identity from `char_product_manager_keyart_v1`.
- `char_product_manager_head_icon`: front or 3/4 face, business blue/gray palette, minimal roadmap cue, preserve PM identity.
- Busts should be tight but readable mid-shot portraits, and head icons should prioritize silhouette, face, and class markers over costume detail.

Validation checklist after generation:
- Each output exists in its target folder.
- Busts read clearly at UI scale and preserve the class palette and personality.
- Head icons remain readable at small size, with no text, watermark, or cluttered background.

## Generated Outputs

Character busts and head icons:
- `Resources/Art/Generated/P0/characters/char_backend_bust_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_frontend_bust_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_tester_bust_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_algorithm_bust_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_product_manager_bust_v1/final.png`
- `Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png`

QA and validation:
- `Resources/Art/Generated/P0/characters/character_variants_contact_sheet_v1.png`
- `Resources/Art/Generated/P0/characters/character_variants_validation_v1.json`

Validation notes:
- All ten final files are normalized to `1024x1024` RGB PNG.
- Each generated asset folder contains `raw.png`, `final.png`, prompt metadata, and response metadata.
- `char_product_manager_head_icon_v1` first pass was rejected for identity mismatch and regenerated to match the established female PM key art.
