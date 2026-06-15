# IMPLEMENTATION_STATUS

## 2026-06-16

### Implemented

- Programmer shared utility cards now have concrete data-driven effects:
  - `card_shared_rollback` gains block and clears weak, vulnerable, and anxiety while leaving heavier statuses intact.
  - `card_shared_standup` gains block, draws a replacement card, and refunds energy.
  - `card_shared_meeting_mute` is targetable and reduces the selected enemy attack intent.
- Automated combat coverage now includes the remaining implemented relic behaviors for `relic_hair_shampoo`, `relic_lumbar_cushion`, `relic_frontend_design_link`, `relic_figma_library`, `relic_gantt_roadmap`, and `relic_paper_citation`.
- Regenerated prototype config output through `DataTables/gen_client.sh`, refreshing both `Data/Generated/Config/game_config.json` and `DataTables/Datas/*.csv`.
- Automated combat tests now cover the shared utility cards through actual card play in battle.

### Verified

Run:

```bash
DataTables/gen_client.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/linyiming/Projects/GodotProjects/withgai --script res://Scripts/Tests/TestRunner.gd
```

Result:

- `DataTables/gen_client.sh` completed through the existing prototype fallback generator.
- Godot test runner completed with `TEST_RESULT: PASSED`.
- Godot MCP `run_project` + `get_debug_output` verified project startup with empty `errors`.

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
  - Attached/source tables for effect groups, effect entries, enemy intent groups, phase groups, reward profiles, and shop pools
  - 195 cards, 16 enemies, 8 random events
- Product manager starter deck now includes attack cards, so all five First Playable classes can complete the first combat loop.
- Combat has expanded target resolution for selected, all enemies, random enemy, lowest HP enemy, and highest priority enemy.
- Battle UI now supports selecting an enemy target before playing targeted cards.
- Battle UI now displays localized class resource labels and readable status names instead of raw runtime dictionaries.
- Rest upgrade can now target a chosen card, and upgraded cards have live battle effects through reduced cost and stronger numeric effects.
- Enemy intent data now includes specialty behaviors for representative enemies and bosses: pollution, multi-hit attacks, summons, player boon cleansing, and phase shifts.
- BattleService now executes data-driven `multi_attack`, `pollute`, `spawn`, `cleanse_player`, and `phase_shift` intents.
- `PhaseGroupDef` now drives threshold-based enemy and Boss phase scripts for representative elites, top-floor enemies, and all three bosses.
- BattleService now triggers phase actions when enemy HP crosses configured thresholds, including block gains, pollution, summons, player debuffs/cleanse, and forced next intent.
- Three pollution/curse cards exist as generated config content: `card_status_option_promise`, `card_status_meeting_minutes`, and `card_curse_next_year_promotion`.
- Core short debuffs now have live combat rules: weak reduces outgoing damage, vulnerable increases incoming damage, overtime ticks on round start, and short debuffs decay.
- Combat status application now synchronizes visible class resources, including tester Bug/case/Diff marks and product manager requirement-change/priority marks.
- Godot script warning cleanup has removed the current MCP debug-output warnings from project startup.
- Representative triggers now exist for battle start, round start/end, card played, damage taken, enemy defeated, elite reward, shop purchase, and core status application.
- Several starter/common/career relics now have live behavior: blue light glasses, cold brew bucket, standing desk, parking pass, employee coupon, read replica, error log repo, backend gray release, tester automation framework, algorithm local cluster, and PM review minutes.
- Run counters and meta settlement now record battles, elites, events, shops, rests, defeated enemies, highest floor, and defeated bosses.
- Suspend saves now include a meta-state snapshot.
- Battle suspend/continue now stores `active_battle_state`, restores `BattleService`, and keeps player hand/energy/enemies/log state across save roundtrips.
- Battle UI now has save and main-menu actions, and non-terminal battle actions auto-save the current battle snapshot.
- Reward UI now supports explicit card selection, relic selection, skipping either reward type, and a final confirm action.
- RewardService now validates selected card/relic IDs against the pending reward candidates and no longer auto-grants the first relic.
- Event choices now apply concrete RunState effects for currency, spirit recovery/loss, random card gain, random relic gain without duplicates, card removal, and card upgrades without duplicate upgrade records.
- Shop now supports `ShopPoolDef.refresh_cost` stock refresh, filters owned relics out of shop stock, preserves one-time card removal state, and does not consume first-purchase discounts when refreshing.
- Shop card removal now supports choosing a specific deck card in the UI; failed targeted removals do not charge currency or consume the one-time removal.
- Run settlement now writes a stable `settlement_state`, is idempotent for currency, and RunResult displays run milestones such as battles, elites, events, shops, rests, enemies, bosses, floor, and earned meta currency.
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
- combat target resolution, battle target selection, upgraded card effects, enemy specialty intents, and representative relic triggers
- tester and product manager status-to-resource synchronization
- enemy pollution, multi-hit attacks, summons, boon cleansing, and phase shifting
- Boss and elite threshold phase scripts, including one-shot phase triggering and forced intent checks
- weak/vulnerable/overtime status hooks and short debuff decay
- cold brew bucket and error log repo relic behavior
- chapter map generation and map constraints
- battle victory and reward generation
- reward acceptance, selected card/relic claim, relic skipping, invalid candidate rejection, and duplicate relic protection
- shop card/relic purchase, first-purchase discount, targeted card removal, failed removal no-charge behavior, refresh cost, refresh count, owned-relic filtering, and remove-state preservation after refresh
- event option resolution and concrete event effects: gain/lose currency, recover/lose spirit, add card, add relic, remove card, and upgrade card
- rest recovery, selected card upgrade, and upgraded-card battle behavior
- map and battle suspend save roundtrip with meta snapshot
- meta settlement, idempotent settlement summaries, victory bonus, and milestone recording
- Boss chapter progression and final victory marker

Also verified:

```bash
DataTables/gen_client.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/linyiming/Projects/GodotProjects/withgai --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path /Users/linyiming/Projects/GodotProjects/withgai
```

Godot MCP verified:

- `get_godot_version`: `4.6.1.stable.official.14d19694e`
- `get_project_info`: 11 scenes, 24 scripts, 473 assets
- `run_project` + `get_debug_output`: project starts successfully with empty `errors`

### Tooling Status

- Godot CLI works at `/Applications/Godot.app/Contents/MacOS/Godot`.
- Codex MCP config has been updated for `@coding-solo/godot-mcp` using `command = "npx"`, `args = ["@coding-solo/godot-mcp"]`, `DEBUG = "true"`, and `GODOT_PATH = "/Applications/Godot.app/Contents/MacOS/Godot"`.
- The current Codex tool layer exposes Godot MCP, and project startup has been verified through MCP.
- Local `.NET SDK` is `7.0.200`; Luban 4.x requires `.NET SDK 8+`.
- `DataTables/gen_client.sh` supports real Luban generation when `LUBAN_DLL` is set. Without it, it refreshes prototype runtime JSON through `Tools/build_config.mjs`.

### Remaining Gaps Toward Full Game

- Real Luban 4.x generation has not been executed in this environment because `.NET SDK 8+` and `LUBAN_DLL` are not available.
- Combat balance, full status hook matrix, remaining relic triggers, and full visual polish remain prototype-level.
- Missing P0 representative card illustrations are still represented by placeholder card UI.
