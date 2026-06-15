# IMPLEMENTATION_STATUS

## 2026-06-15

### Implemented

- Godot entrypoint: `res://Scenes/Main.tscn`
- Autoload root: `res://Scripts/Autoload/AppRoot.gd`
- First Playable classes: backend, frontend, tester, algorithm, product manager
- HR: visible as an expansion/placeholder class, not battle-enabled
- Scenes: main menu, class select, map, battle, reward, shop, event, rest, run result, meta progression
- Runtime services:
  - `ConfigService`
  - `SaveService`
  - `MetaProgressionService`
  - `RunSession`
  - `MapService`
  - `BattleService`
  - `EffectExecutor`
  - `RewardService`
  - `ContentResolver`
  - `FlowController`
- Data:
  - `Data/Generated/Config/game_config.json`
  - `DataTables/Datas/*.csv`
  - Attached/source tables for effect groups, effect entries, enemy intent groups, reward profiles, and shop pools
  - 192 cards, 16 enemies, 8 random events
- Product manager starter deck now includes attack cards, so all five First Playable classes can complete the first combat loop.
- Combat has expanded target resolution for selected, all enemies, random enemy, lowest HP enemy, and highest priority enemy.
- Battle UI now supports selecting an enemy target before playing targeted cards.
- Rest upgrade can now target a chosen card, and upgraded cards have live battle effects through reduced cost and stronger numeric effects.
- Representative triggers now exist for battle start, round start/end, card played, damage taken, enemy defeated, elite reward, shop purchase, and core status application.
- Several starter/common relics now have live behavior: blue light glasses, standing desk, parking pass, employee coupon, read replica, backend gray release, tester automation framework, algorithm local cluster, and PM review minutes.
- Run counters and meta settlement now record battles, elites, events, shops, rests, defeated enemies, highest floor, and defeated bosses.
- Suspend saves now include a meta-state snapshot.
- Current UI uses generated P0 backgrounds, characters, enemies, relic icons, and placeholder card surfaces where card art is missing.

### Verified

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/linyiming/Projects/GodotProjects/withgai --script res://Scripts/Tests/TestRunner.gd
```

Current checks cover:

- config loading
- content pool and reference validation
- five First Playable starter decks
- five First Playable first-battle victories and reward acceptance
- combat target resolution, battle target selection, upgraded card effects, and representative relic triggers
- chapter map generation and map constraints
- battle victory and reward generation
- reward acceptance
- shop card/relic purchase, first-purchase discount, and card removal
- event option resolution
- rest recovery, selected card upgrade, and upgraded-card battle behavior
- suspend save roundtrip with meta snapshot
- meta settlement and milestone recording
- Boss chapter progression and final victory marker

Also verified:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/linyiming/Projects/GodotProjects/withgai --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path /Users/linyiming/Projects/GodotProjects/withgai
```

### Tooling Status

- Godot CLI works at `/Applications/Godot.app/Contents/MacOS/Godot`.
- Codex MCP config has been updated for `@coding-solo/godot-mcp` using `command = "npx"`, `args = ["@coding-solo/godot-mcp"]`, `DEBUG = "true"`, and `GODOT_PATH = "/Applications/Godot.app/Contents/MacOS/Godot"`.
- The current Codex tool layer still does not expose Godot MCP tools until the session/tool layer is reloaded.
- Local `.NET SDK` is `7.0.200`; Luban 4.x requires `.NET SDK 8+`.
- `DataTables/gen_client.sh` supports real Luban generation when `LUBAN_DLL` is set. Without it, it refreshes prototype runtime JSON through `Tools/build_config.mjs`.

### Remaining Gaps Toward Full Game

- Real Luban 4.x generation has not been executed in this environment because `.NET SDK 8+` and `LUBAN_DLL` are not available.
- Godot MCP has not been used directly in this running session because the MCP tools are still not exposed after config changes.
- Combat balance, full status hook matrix, enemy phase scripting, remaining relic triggers, and full visual polish remain prototype-level.
- Missing P0 representative card illustrations are still represented by placeholder card UI.
