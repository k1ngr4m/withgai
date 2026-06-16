# IMPLEMENTATION_STATUS

## 2026-06-16

### Implemented

- Backend `card_backend_flush_all` now works as the designed cache finisher:
  - generated config marks `cache` as a `deal_damage` hook
  - the card consumes all stored cache and converts each stack into bonus single-target damage
  - runtime consumption keeps backend cache resource/status values synchronized downward
- Frontend `card_frontend_component_reuse` now works as the designed component-combo card:
  - generated config requires an existing component before copying
  - successful reuse copies one component and draws a card
  - failed reuse does not fabricate a component or draw
- Tester `card_tester_report_lock` now works as the designed status finisher:
  - generated config gives it Bug, case, and Diff damage multipliers
  - Bug and Diff now declare `deal_damage` timing hooks
  - runtime damage reads the selected enemy's Bug / case / Diff stacks
- Algorithm and product manager P0 card-art batches are now wired into runtime config:
  - 10 accepted algorithm illustrations plus contact sheet and validation manifest
  - 10 accepted product manager illustrations plus contact sheet and validation manifest
  - `Tools/build_config.mjs` maps the product manager `card_pm_change_wording` card to the generated `pm_change_request` asset slug
- Main menu has been upgraded from a plain button list to a full first-screen UI:
  - full-screen generated office background with dark readability overlay
  - title, subtitle, playable-content counters, current suspend-save status
  - right-side action panel for new run, continue, meta progression, and exit
  - bottom five-class preview strip using existing class portrait assets and class colors
- Career unlock tree presentation now has reusable `MetaProgressionService` helpers for class availability, unlock condition text, and milestone progress.
- `ClassSelectScene` now shows each class status, unlock condition, and current progress while keeping HR visible but not battle-playable.
- `MetaProgressionScene` now renders the career tree as readable class nodes with difficulty, summary, unlock condition, current progress, and HR expansion-placeholder messaging.
- Real Luban generation is now wired into the project-local data pipeline:
  - `DataTables/gen_client.sh` auto-detects `Tools/Luban/Luban.dll`
  - uses `.NET SDK 8` from `~/.dotnet/dotnet` when the default `dotnet` is older
  - emits per-table JSON into `Data/Generated/Config/*.json`
  - emits GDScript schema output into `Scripts/Generated/Config`
  - repacks the generated tables into the runtime `Data/Generated/Config/game_config.json` through `Tools/pack_luban_config.mjs`
- `StatusDef.timing_hooks` now declares live runtime hooks for core debuffs and representative class statuses, including anxiety/overtime round-start hooks, weak/vulnerable damage hooks, service round hooks, and targeting/status-resource hooks.
- Automated combat coverage now verifies anxiety round-start energy loss and decay in addition to weak, vulnerable, and overtime behavior.
- `BattleService` now resolves backend `service_online` from either the visible status stack or backend `services` resource stack, using the higher value so synced status/resource values do not double count.
- Automated combat coverage now verifies `service_online` round-start cache/block generation, resource+status no-double-count behavior, and round-end enemy damage.
- Frontend `style_layer` now has live damage-hook behavior: `deal_damage` reads either the frontend resource stack or visible status stack, adds the layer count as damage bonus, and consumes one layer after a successful damage effect without double-counting synced resource/status values.
- Tester `Diff` now has a live bug-injection hook: targets with Diff gain an extra Bug when `inject_bug` resolves, consume one Diff stack, sync the tester `diff_tags` resource downward, and reduce attack intent using the final Bug amount.
- Algorithm `compute` now has live X-finisher behavior: `card_algo_global_optimum` scales damage from paid X energy and stored compute, consumes the spent compute, and still works with the starter relic's first X-card energy refund.
- Algorithm `relic_gpu_training_card` now exists in the generated relic pool and adds one extra compute the first time compute is gained each battle.
- Algorithm `complexity` is now a real pressure resource instead of a passive counter:
  - `StatusDef.params` is now available in Luban CSV/JSON/GDScript output for status-specific tuning.
  - `complexity` declares `add_compute` and `round_start` hooks with configured compute-to-complexity gain and pressure threshold.
  - gaining compute raises complexity, including the bonus compute from `relic_gpu_training_card`.
  - high complexity reduces round-start energy using configured status params while reading resource/status stacks without double counting.
- Product manager priority now has a real target-resolution loop:
  - `card_pm_schedule_compress`, `card_pm_roadmap`, and `card_pm_snowball` target the highest-priority enemy.
  - Auto-resolved target cards no longer require manual enemy selection in battle UI.
  - Requirement-change marks from those attacks are applied to the resolved priority target.
- Product manager `requirement_change` now has live enemy-action rewriting:
  - `StatusDef.params` configures intent amount reduction and per-action stack consumption.
  - before affected enemies act, attack / multi-attack / block / debuff intent amounts are reduced.
  - consumed marks reduce both the enemy status stack and the product manager `requirement_change_marks` resource display.
- Automated meta-progression coverage now verifies all six global workstation upgrades through their live runtime paths:
  - `meta_chair`, `meta_coffee_beans`, `meta_privacy_screen`, and `meta_hard_drive` at run start
  - `meta_nap_bed` at rest recovery
  - `meta_canteen_card` at first shop purchase
  - workstation purchase cost/level validation and career-unlock purchase rejection
- `EffectExecutor.move_card` now performs real battle pile movement between hand, draw, discard, and exhaust piles, including optional named-card selection and default top-card movement.
- `EffectExecutor` now executes run-state reward/deck effects directly for `add_random_card`, `add_random_relic`, `upgrade_card`, and `remove_card`, so these no longer degrade to placeholder logs outside event handling.
- Card illustration presentation now uses `CardDef.art_path` in reusable UI card buttons for battle hands, reward choices, shop stock, and shop removal picks.
- `card_frontend_component_reuse` now has a generated P0 card illustration wired through `Tools/build_config.mjs`, Luban CSV/JSON output, and runtime config.
- `Tools/build_config.mjs` now auto-wires matching `Resources/Art/Generated/P0/cards/card_illust_<card_id>_v1/final.png` assets into `CardDef.art_path`; current generated config exposes 49 card illustrations.
- The first frontend P0 card-art batch is now committed and wired into runtime config:
  - 10 accepted frontend card illustrations plus contact sheet and validation manifest.
  - `Tools/build_config.mjs` includes explicit art-slug aliases for generated asset IDs that intentionally differ from card IDs.
  - Generated config now exposes the complete frontend P0 set plus existing backend card illustrations.
- The first tester P0 card-art batch is now wired into runtime config:
  - 10 accepted tester card illustrations plus contact sheet and validation manifest.
  - Matching `card_illust_tester_*_v1/final.png` assets are auto-wired into `CardDef.art_path` through the existing config build pipeline.
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

- `DataTables/gen_client.sh` completed through real Luban generation using `Tools/Luban/Luban.dll` and `.NET SDK 8`.
- Godot test runner completed with `TEST_RESULT: PASSED`.
- Godot test runner now checks `StatusDef.timing_hooks` declarations for anxiety, overtime, weak, vulnerable, and service online.
- Godot test runner now checks the live `service_online` round-start and round-end hooks.
- Godot test runner now checks frontend `style_layer` damage bonus and consumption from both resource-sourced and status-sourced stacks.
- Godot test runner now checks frontend `card_frontend_component_reuse` generated params, copy-on-existing-component behavior, draw-on-success behavior, and no-copy/no-draw behavior without an existing component.
- Godot test runner now checks tester `card_tester_report_lock` generated params, Bug/Diff damage-hook declarations, and real combat damage scaling from Bug, case, and Diff stacks.
- Godot test runner now checks tester `Diff` hook declaration, extra Bug injection, Diff consumption, `diff_tags` resource sync, and final intent reduction.
- Godot test runner now checks backend `cache` damage-hook declaration, `card_backend_flush_all` generated params, cache-scaled damage, and cache consumption.
- Godot test runner now checks algorithm `compute` damage-hook declaration, X-finisher damage scaling, compute consumption, and local-cluster energy refund.
- Godot test runner now checks `relic_gpu_training_card` config, algorithm ownership, compute trigger declaration, first compute bonus, and one-shot behavior.
- Godot test runner now checks `complexity` status params, compute-to-complexity gain, GPU bonus complexity gain, high-complexity round-start pressure, and resource/status no-double-count behavior.
- Godot test runner now checks product manager priority target routing, including ignored low-priority selected targets and requirement-change marking on the resolved target.
- Godot test runner now checks product manager `requirement_change` status params, enemy-action intent reduction, stack consumption, and resource sync after consumption.
- Godot test runner now checks career-tree labels, HR non-playable status, and milestone progress text.
- Godot test runner now checks global workstation upgrade purchases plus run-start, rest, and shop effects for every implemented upgrade.
- Godot test runner now checks `move_card` named-card and top-card movement across combat piles.
- Godot test runner now checks `EffectExecutor` deck/relic reward effects update `RunState` and active battle upgrade state.
- Godot test runner now checks configured card art paths load, including `card_frontend_component_reuse`.
- Godot test runner now checks bulk card-art auto-wiring through an existing backend card illustration and a minimum configured-card-art count.
- Godot test runner now explicitly checks all 10 frontend P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot test runner now explicitly checks all 10 tester P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot test runner now explicitly checks all 10 algorithm and all 10 product manager P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot MCP `get_project_info` reports Godot `4.6.1.stable.official.14d19694e`, 11 scenes, and 25 scripts.
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
- Local default `dotnet` is still `7.0.200`, but `.NET SDK 8.0.422` is available at `~/.dotnet/dotnet`.
- `DataTables/gen_client.sh` supports real Luban generation through `Tools/Luban/Luban.dll` or `LUBAN_DLL`. Without Luban it still refreshes prototype runtime JSON through `Tools/build_config.mjs`.

### Remaining Gaps Toward Full Game

- Combat balance, full status hook matrix, and full visual polish remain prototype-level.
- Remaining card illustration gaps are outside the currently wired backend/frontend/tester/algorithm/product-manager P0 batches and still use placeholder card UI.
