# batch_2026-06-15_p0_relic_icons_programmer_01

Status: generated_processed

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Skill routing:
- Use `$generate2dsprite` for the visible icon assets.
- Asset type: `prop`
- Action: `single`
- Art style: `clean_hd`
- Bundle: six independent transparent icon assets, one output folder per relic.
- Background requirement: transparent final icon; if a raw sheet is used, it must use solid `#FF00FF` and be processed with the sprite pipeline.

Target folders:
- Resources/Art/Generated/P0/icons/relic_icon_blue_light_glasses_v1/
- Resources/Art/Generated/P0/icons/relic_icon_cold_brew_bucket_v1/
- Resources/Art/Generated/P0/icons/relic_icon_hair_shampoo_v1/
- Resources/Art/Generated/P0/icons/relic_icon_lumbar_cushion_v1/
- Resources/Art/Generated/P0/icons/relic_icon_standing_desk_v1/
- Resources/Art/Generated/P0/icons/relic_icon_parking_pass_v1/

Recommended generation shape:
- Prefer one-by-one generation for each icon for stronger readability and easier approval.
- A compact `2x3` sheet is acceptable only if the model can keep each relic centered with clear padding and no edge touches.

## Prompt Records

### `relic_icon_blue_light_glasses_v1`

```text
Use $generate2dsprite to create a single clean_hd relic icon for a workplace roguelike card game. Subject: modern office blue-light glasses, centered single object, gray-blue frame, cold white reflection on the lenses, high contrast, crisp commercial 2D game icon style, readable at small UI size, transparent final background or solid #FF00FF raw background for processing. No text, no label, no logo, no character, no busy scene, no border.
```

### `relic_icon_cold_brew_bucket_v1`

```text
Use $generate2dsprite to create a single clean_hd relic icon for a workplace roguelike card game. Subject: cold brew coffee bucket, centered single object, dark coffee container with condensation, subtle modern office coffee-system details, high contrast, crisp commercial 2D game icon style, readable at small UI size, transparent final background or solid #FF00FF raw background for processing. No text, no label, no logo, no character, no busy scene, no border.
```

### `relic_icon_hair_shampoo_v1`

```text
Use $generate2dsprite to create a single clean_hd relic icon for a workplace roguelike card game. Subject: anti-hair-loss shampoo bottle, centered single object, modern office-worker black-comedy tone, clean bottle silhouette, cool gray-blue plastic with small office-satire accent color, high contrast, crisp commercial 2D game icon style, readable at small UI size, transparent final background or solid #FF00FF raw background for processing. No text, no label, no logo, no character, no busy scene, no border.
```

### `relic_icon_lumbar_cushion_v1`

```text
Use $generate2dsprite to create a single clean_hd relic icon for a workplace roguelike card game. Subject: ergonomic lumbar cushion, centered single object, soft gray-blue cushion shape, clear supportive curve, modern office chair accessory feeling, high contrast, crisp commercial 2D game icon style, readable at small UI size, transparent final background or solid #FF00FF raw background for processing. No text, no label, no logo, no character, no busy scene, no border.
```

### `relic_icon_standing_desk_v1`

```text
Use $generate2dsprite to create a single clean_hd relic icon for a workplace roguelike card game. Subject: simplified modern standing desk, centered single object, clear adjustable legs and tabletop silhouette, subtle cool office-tech highlights, high contrast, crisp commercial 2D game icon style, readable at small UI size, transparent final background or solid #FF00FF raw background for processing. No text, no label, no logo, no character, no busy scene, no border.
```

### `relic_icon_parking_pass_v1`

```text
Use $generate2dsprite to create a single clean_hd relic icon for a workplace roguelike card game. Subject: office-campus parking monthly pass card, centered single object, simple pass-card shape with corporate parking-garage visual cues but no readable letters, cool gray-blue and white palette with small warning-orange accent, high contrast, crisp commercial 2D game icon style, readable at small UI size, transparent final background or solid #FF00FF raw background for processing. No text, no label, no logo, no character, no busy scene, no border.
```

Validation checklist after generation:
- Every relic folder contains a prompt file, API response metadata, and generated raw PNG.
- Raw PNGs are valid square RGB images.
- Transparent `prop.png` files are 1024x1024 RGBA and have alpha.
- No accepted icon should have readable text, watermark, logo, character, or busy scene background.
- If later generated as a sheet, `pipeline-meta.json` parses and has no accepted edge-touch entries.

Prompt order for a sheet-based fallback:
- `relic_icon_blue_light_glasses_v1`
- `relic_icon_cold_brew_bucket_v1`
- `relic_icon_hair_shampoo_v1`
- `relic_icon_lumbar_cushion_v1`
- `relic_icon_standing_desk_v1`
- `relic_icon_parking_pass_v1`

## Generated Raw Files

- [relic_icon_blue_light_glasses_v1/raw.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_blue_light_glasses_v1/raw.png)
- [relic_icon_cold_brew_bucket_v1/raw.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_cold_brew_bucket_v1/raw.png)
- [relic_icon_hair_shampoo_v1/raw.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_hair_shampoo_v1/raw.png)
- [relic_icon_lumbar_cushion_v1/raw.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_lumbar_cushion_v1/raw.png)
- [relic_icon_standing_desk_v1/raw.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_standing_desk_v1/raw.png)
- [relic_icon_parking_pass_v1/raw.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_parking_pass_v1/raw.png)
- [relic_icons_programmer_contact_sheet_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icons_programmer_contact_sheet_v1.png)

Generation notes:
- Generated through the user-provided OpenAI-compatible `/v1/images/generations` endpoint using JSON requests.
- The endpoint returned 1254x1254 RGB PNGs even when 1024x1024 was requested.
- These raw files are project-local source art retained next to final transparent `prop.png` files.

## Final Transparent Files

- [relic_icon_blue_light_glasses_v1/prop.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_blue_light_glasses_v1/prop.png)
- [relic_icon_cold_brew_bucket_v1/prop.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_cold_brew_bucket_v1/prop.png)
- [relic_icon_hair_shampoo_v1/prop.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_hair_shampoo_v1/prop.png)
- [relic_icon_lumbar_cushion_v1/prop.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_lumbar_cushion_v1/prop.png)
- [relic_icon_standing_desk_v1/prop.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_standing_desk_v1/prop.png)
- [relic_icon_parking_pass_v1/prop.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icon_parking_pass_v1/prop.png)
- [relic_icons_programmer_transparent_contact_sheet_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icons_programmer_transparent_contact_sheet_v1.png)
- [relic_icons_programmer_validation_v1.json](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/icons/relic_icons_programmer_validation_v1.json)
