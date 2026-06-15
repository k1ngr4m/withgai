# P0 Batch Manifest 2026-06-12

## Batch Scope
- Batch ID: `2026-06-12_p0_env_ui_and_boss_01`
- Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)
- Goal:
  - 第二章战斗背景
  - 第三章战斗背景
  - 主菜单背景
  - 职业选择页背景
  - 第一章 Boss 主立绘
- Generation mode:
  - Built-in `image_gen`
  - Prompt authored manually according to `$generate2dmap` / `$generate2dsprite` skill constraints

## Output Files
- [bg_battle_ch2_management_zone_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/bg_battle_ch2_management_zone_v1.png)
- [bg_battle_ch3_ceo_floor_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/bg_battle_ch3_ceo_floor_v1.png)
- [ui_main_menu_bg_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png)
- [ui_class_select_bg_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/backgrounds/ui_class_select_bg_v1.png)
- [boss_pitch_supervisor_v1.png](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Art/Generated/P0/characters/boss_pitch_supervisor_v1.png)

## Prompt Records

### `bg_battle_ch2_management_zone_v1`
```text
Use case: stylized-concept
Asset type: battle background for a workplace roguelike card game
Primary request: create the chapter 2 middle-management office battle background following the project asset prompt manual and generate2dmap baked_scene_mode guidance
Scene/backdrop: a middle-management office zone in a modern corporation, with glass meeting rooms, approval desks, KPI screens, performance dashboards, long corridor sightlines, structured partitions, and colder more bureaucratic space than chapter 1
Subject: no characters, no UI, no text, no readable signage; this is a flat battle background only
Composition: wide 16:9 horizontal background, strong readable spatial hierarchy, clear central confrontation area, enough clean lower and center space for combat UI and characters, sightlines that emphasize pressure and office hierarchy
Style: clean HD 2D commercial card-game background, polished 2D game art, readable office layout, absurd corporate satire, controlled visual density, subtle surreal pressure but not horror
Color and lighting: colder white lighting, cool gray-blue environment, restrained cyan highlights, slightly harsher contrast than chapter 1
Mood: chapter 2 management pressure, bureaucratic control, efficient but oppressive corporate order
Constraints: no baked gameplay props that need separate editing, no cyberpunk control room, no horror lab, no cluttered unreadable monitors, no logos, no watermark
```

### `bg_battle_ch3_ceo_floor_v1`
```text
Use case: stylized-concept
Asset type: battle background for a workplace roguelike card game
Primary request: create the chapter 3 executive floor battle background following the project asset prompt manual and generate2dmap baked_scene_mode guidance
Scene/backdrop: a top corporate executive zone with glass, steel, luxury office materials, giant meeting screen walls, panoramic city skyline, central confrontation area, and subtle surreal distortion that makes the space feel like the headquarters of a living company machine
Subject: no characters, no UI, no text, no readable signage; this is a flat battle background only
Composition: wide 16:9 horizontal background, strong central battle area, enough clean lower and center space for combat UI and characters, more monumental framing than chapter 2, readable depth and hierarchy
Style: clean HD 2D commercial card-game background, polished 2D game art, readable executive office layout, corporate satire, oppressive but clear, not horror, not an over-detailed concept painting
Color and lighting: cold white architectural lighting, cool steel and glass palette, restrained city glow, luxurious but hostile atmosphere
Mood: final chapter authority, corporate capital as environment, intimidating and controlled
Constraints: no sci-fi spaceship bridge, no fantasy throne room, no horror flesh architecture, no baked runtime props, no logos, no watermark
```

### `ui_main_menu_bg_v1`
```text
Use case: stylized-concept
Asset type: main menu background for a workplace roguelike card game
Primary request: create the main menu key visual background from the project asset prompt manual
Scene/backdrop: a modern high-rise office tower at night, still brightly lit, with subtle KPI flows, approval chains, meeting schedules, and data ribbons lightly mutating the building into a living corporate machine
Subject: no characters in the center, no logo, no text, no UI elements; this is a menu background only
Composition: wide 16:9 horizontal background with strong visual impact, cinematic office-building silhouette, large central and lower safe space reserved for title and menu buttons
Style: clear 2D commercial game menu art, polished 2D card-game background, workplace fantasy satire, absurd office mutation but not horror, readable shapes, not a cyberpunk city poster
Color and lighting: cold white office windows, gray-blue tower mass, small accents of fluorescent green and warning red, controlled contrast
Mood: ominous but playful corporate absurdity, a building that never truly clocks out
Constraints: no full horror tower, no text logo, no characters occupying center UI space, no watermark, no photorealistic matte painting feel
```

### `ui_class_select_bg_v1`
```text
Use case: stylized-concept
Asset type: class selection background for a workplace roguelike card game
Primary request: create the class selection background from the project asset prompt manual
Scene/backdrop: an absurd corporate promotion and role-display hall inside a modern office building, with glass display walls, class presentation platforms, cold white lighting, subtle role-themed graphic motifs, and a premium office-tech atmosphere
Subject: no characters, no text, no UI widgets; this is a class selection background only
Composition: wide 16:9 horizontal background, clear left and right presentation zones for class characters, central safe space for class summary and selection UI, readable depth and balanced staging
Style: clear 2D commercial card-game UI background, polished 2D game art, workplace fantasy satire, modern office interior with curated display-space feel, not a fantasy guild hall, not a fashion stage show
Color and lighting: cold white and gray-blue base, subtle business-tech highlights, clean architectural lines, controlled contrast
Mood: preparation, role identity, promotion-path absurdity, premium but still office-themed
Constraints: no crowded objects, no text, no watermark, no characters occupying the character podium spaces, no generic sci-fi showroom
```

### `boss_pitch_supervisor_v1`
```text
Use case: stylized-concept
Asset type: boss key art for a workplace roguelike card game
Primary request: create the chapter 1 boss Pitch Supervisor key art from the project asset prompt manual
Scene/backdrop: a bright but oppressive office area warped by presentation decks, roadmap boards, floating pie charts, and performance-stage exaggeration
Subject: the Pitch Supervisor boss, a modern middle-management supervisor mutated into a corporate promise monster, semi-realistic polished 2D commercial card-game boss illustration, larger-than-normal human figure, holding a huge roadmap board, stock-option pie chart, promise scrolls, and a speech-amplifier device, surrounded by hollow motivational paper slips and glossy fake-future graphics, exaggerated, self-confident, manipulative pose
Composition: vertical boss character illustration, dominant single subject, strong silhouette, enough crop space for battle UI and later portrait extraction
Style: clear 2D commercial boss art, semi-realistic stylized illustration, polished 2D game art, workplace fantasy satire, absurd office mutation but not horror, readable shapes, not a cosmic monster, not text-heavy infographic art
Color and lighting: bright office whites and gray-blues with tempting orange, pale gold, and deceptive optimistic glow accents
Mood: charismatic pressure, manipulative optimism, early-boss authority, a smiling trap made of office ambition
Constraints: no final-boss scale, no readable text on charts, no horror flesh mutation, no watermark, no logo, no extra limbs, preserve office-manager identity
```

## Notes
- This batch continues the `P0` environment and boss baseline.
- Next recommended batch:
  - `bg_map_floor_navigation`
  - `ui_reward_bg`
  - `bg_rest_break_room`
  - `bg_shop_vending_machine`
  - `node_icon_combat_set`
