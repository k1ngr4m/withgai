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
- chapter map generation and map constraints
- battle victory and reward generation
- reward acceptance
- shop card/relic purchase and card removal
- event option resolution
- rest recovery and card upgrade
- suspend save roundtrip
- Boss chapter progression and final victory marker

Also verified:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/linyiming/Projects/GodotProjects/withgai --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path /Users/linyiming/Projects/GodotProjects/withgai
```

### Tooling Status

- Godot CLI works at `/Applications/Godot.app/Contents/MacOS/Godot`.
- Codex MCP config has been updated for `@coding-solo/godot-mcp`, but the current Codex tool layer still does not expose Godot MCP tools until the session/tool layer is reloaded.
- Local `.NET SDK` is `7.0.200`; Luban 4.x requires `.NET SDK 8+`.
- `DataTables/gen_client.sh` supports real Luban generation when `LUBAN_DLL` is set. Without it, it refreshes prototype runtime JSON through `Tools/build_config.mjs`.

### Remaining Gaps Toward Full Game

- Real Luban 4.x generation has not been executed in this environment because `.NET SDK 8+` and `LUBAN_DLL` are not available.
- Godot MCP has not been used directly in this running session because the MCP tools are still not exposed after config changes.
- Combat balance, advanced status behavior, enemy phase scripting, richer relic triggers, and full visual polish remain prototype-level.
- Missing P0 representative card illustrations are still represented by placeholder card UI.
