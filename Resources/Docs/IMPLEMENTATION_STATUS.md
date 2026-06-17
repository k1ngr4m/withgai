# IMPLEMENTATION_STATUS

## 2026-06-16

### Implemented

- Backend `card_backend_api_gateway` now works as the designed round-start service payoff:
  - generated config applies a new `api_gateway` self status instead of the generic service placeholder
  - `api_gateway` declares a `round_start` hook with configurable block amount, service threshold, and draw amount
  - runtime grants block each player round start and draws extra cards when the backend has at least 2 services online
- Backend `card_backend_redis_warmup` now works as the designed next-turn tempo setup:
  - generated config grants a large cache burst and applies hidden `redis_warmup`
  - round start converts `redis_warmup` into a hidden one-card `cost_reduction`
  - hand card costs and play validation read the live discounted cost, and the discount is consumed after use
- Backend `card_backend_message_queue` now works as the designed request-count payoff:
  - generated config applies `request_queue` stacks as a visible backend request resource
  - `request_queue` declares a `round_end` hook with configurable damage per request
  - runtime damages every live enemy at round end and consumes the stored request count afterward
- Backend `card_backend_sharding` now works as the designed cache scaling power:
  - generated config applies a new visible `sharding` self status instead of the generic service placeholder
  - `sharding` declares an `add_cache` hook with configurable extra cache amount
  - runtime grants the extra cache only on the first cache gain each player turn, then resets the trigger next turn
  - service-online cache generation and read-replica cache return now route through the same `add_cache` path
- Backend `card_backend_traffic_shaping` now works as the designed pressure-to-cache skill:
  - generated config gives the card a block effect plus an `add_cache` effect driven by `damage_taken_this_turn`
  - `EffectParams` now supports `from_damage_taken_this_turn` and `damage_taken_divisor` for data-driven pressure conversion
  - runtime folds converted cache into the normal `add_cache` path, so sharding and other cache hooks can react to it
- Backend `card_backend_circuit_breaker` now works as the designed service-aware starter defense:
  - generated config uses a dedicated `circuit_breaker` effect instead of generic block/cache filler
  - runtime grants base block, adds extra block and cache from existing service count, and adds pressure block when visible enemy attack intent is high
  - service stacks stay online, making the starter card a real payoff for publishing services early
- Backend `card_backend_service_degrade` now works as the designed service-preserving mitigation skill:
  - generated config uses a dedicated `service_degrade` effect instead of generic block/draw/cache filler
  - runtime lowers all visible attack and multi-attack enemy intents, then gains block from existing service count without consuming services
  - if any service is online, the card preserves tempo by adding a small cache reward through the normal cache path
- Backend `card_backend_trace_chain` now works as the designed production-inspection tutor:
  - generated config uses a dedicated `fetch_service_card` effect instead of generic block/cache filler
  - runtime scans the draw pile from the top down and moves the first service-related card into hand
  - service-related cards are identified through generated effect groups, including deployed services and backend service statuses
- Backend `card_backend_flush_all` now works as the designed cache finisher:
  - generated config marks `cache` as a `deal_damage` hook
  - the card consumes all stored cache and converts each stack into bonus single-target damage
  - runtime consumption keeps backend cache resource/status values synchronized downward
- Frontend `card_frontend_pixel_tap` now works as the designed starter combo attack:
  - generated config keeps the base single-target damage and adds a played-card threshold bonus
  - runtime deals base damage as the first card and adds light damage when another card was already played this turn
  - this gives the four-copy frontend starter attack its intended low-cost combo payoff
- Frontend `card_frontend_component_reuse` now works as the designed component-combo card:
  - generated config requires an existing component before copying
  - successful reuse copies one component and draws a card
  - failed reuse does not fabricate a component or draw
- Frontend `card_frontend_flex_layout` now works as the designed starter component-builder:
  - generated config uses block plus `add_component` instead of default style-layer filler
  - runtime grants the configured block and creates one component without creating style layers
  - this makes the four-copy frontend starter defense card feed component-combo cards as intended
- Frontend `card_frontend_slice_sprint` now works as the designed starter tempo card:
  - generated config uses draw plus `add_style_layer` instead of default block/component filler
  - runtime draws a card and creates one style layer without granting block or creating components
  - this gives the frontend starter deck a real zero-cost style-layer setup card
- Frontend `card_frontend_hotfix_style` now works as the designed starter amplifier:
  - generated config applies hidden `hotfix_style` instead of default block/style filler
  - the next damage card gains a virtual style-layer bonus and then consumes the hotfix state
  - unused hotfix state expires at player turn end, preserving the next-attack setup window
- Frontend `card_frontend_pixel_align` now works as the designed component-aware repair card:
  - generated config uses a dedicated `pixel_align` effect instead of generic block/draw/component filler
  - runtime grants base block, then adds bonus block when the frontend already has at least one component
  - the card no longer creates components or draws cards, keeping it focused as a 0-cost defensive repair
- Frontend `card_frontend_compat_patch` now works as the designed compatibility repair card:
  - generated config uses `cleanse_debuff` plus hidden `compatibility_patch` status instead of generic block/style filler
  - runtime clears one stack of a player debuff, then preserves style layers when damage would normally consume them
  - the protection expires at player turn end, preserving the "this turn" constraint
- Frontend `card_frontend_state_boost` now works as the designed fourth-card damage setup:
  - generated config applies a new `state_boost` self status instead of the generic style-layer placeholder
  - `state_boost` declares a `card_played` hook with configurable fourth-card trigger and style-layer amount
  - runtime grants the style layer before the fourth card resolves, so a fourth-card attack immediately receives the damage boost
- Frontend `card_frontend_vue_suite` now works as the designed round-start component engine:
  - generated config applies the new `vue_suite` self status instead of the generic style-layer placeholder
  - `vue_suite` declares a `round_start` hook and configurable `component_amount`
  - each player round start generates components through the existing `add_component` path, including component relic hooks such as Figma library
- Frontend `card_frontend_motion_overload` now works as the designed played-card-count attack:
  - generated config gives it a `cards_played_multiplier`
  - runtime damage now reads `cards_played_this_turn`, including the current card after it is played
  - the card scales from low setup damage into a high-output combo payoff later in the turn
- Frontend `card_frontend_first_screen` now works as the designed same-turn tempo setup:
  - generated config applies hidden `first_screen_optimization` stacks instead of generic block/style filler
  - runtime reduces each of the next two non-X cards by the configured amount, consuming one stack per card
  - unused stacks expire at player turn end, preserving the "this turn" constraint
- Frontend `card_frontend_crash_animation` now works as the designed style-layer finisher:
  - generated config converts style layers into extra damage hits instead of generic single-hit attack damage
  - runtime damage can now treat style layers as hit-count scaling and consume all style layers after the attack resolves
  - the existing default style-layer bonus still applies to ordinary damage cards and continues to consume only one layer
- Tester `card_tester_auto_regression` now works as the designed round-end Bug trigger:
  - generated config applies a new `auto_regression` self status instead of generic case/draw power filler
  - `auto_regression` declares a `round_end` hook with configurable trigger damage and case gain
  - runtime finds a live enemy with Bug at player round end, triggers regression damage, and syncs the added case resource
- Tester `card_tester_smoke_test` now works as the designed starter scouting defense:
  - generated config grants block and uses `observe_intent` instead of incorrectly adding Diff
  - runtime previews each live enemy's next intent and stores that preview in enemy runtime flags
  - the next enemy intent refresh consumes the preview, making the UI prediction accurate rather than decorative
- Tester `card_tester_boundary_check` now works as the designed boundary-case skill:
  - generated config marks the card as a selected-target skill with data-driven low-HP and high-attack thresholds
  - runtime `boundary_check` applies base cases and adds bonus cases when the selected target is low on HP or showing a high attack / multi-attack intent
  - case resource sync uses the normal case-mark application path
- Tester `card_tester_bug_upgrade` now works as the designed Bug upgrade skill:
  - generated config marks the card as a selected-target skill instead of a self-target filler
  - runtime `upgrade_bug` requires an existing Bug, adds configured Bug stacks, syncs the tester Bug resource, and weakens the target's attack intent
  - targets without Bug do not receive a free Bug from the upgrade effect
- Tester `card_tester_case_matrix` now works as the designed first-case amplifier:
  - generated config applies a new `case_matrix` self status instead of generic case/draw power filler
  - `case_matrix` declares an `add_case` hook with configurable bonus case amount
  - runtime adds the bonus case only on the first case application each player turn, then resets the trigger next turn
- Tester `card_tester_regression_confirm` now works as the designed case-gated regression skill:
  - generated config marks the starter card as selected-target instead of self-target filler
  - runtime `confirm_regression` requires the target to already have case marks before drawing and adding Diff
  - targets without case marks do not receive Diff and do not trigger the draw
- Tester `card_tester_repro_steps` now works as the designed targeted Bug injection starter:
  - generated config marks the card as selected-target and uses `inject_bug` instead of default self-target skill filler
  - runtime injects Bug into the chosen enemy only, leaving unselected enemies untouched
  - the tester starter relic still adds case marks to the reproduced target and syncs Bug/case resources
- Tester `card_tester_92_bugs` now works as the designed multi-Bug rare skill:
  - generated config marks the card as selected-target and uses the shared `inject_bug` effect with multiple hits
  - runtime `inject_bug` now honors data-driven hit count while reusing Diff consumption, Bug resource sync, and intent weakening
  - each hit resolves as a real Bug injection, so existing Bug/Diff relic hooks still apply consistently
- Tester `card_tester_report_lock` now works as the designed status finisher:
  - generated config gives it Bug, case, and Diff damage multipliers
  - Bug and Diff now declare `deal_damage` timing hooks
  - runtime damage reads the selected enemy's Bug / case / Diff stacks
- Algorithm and product manager P0 card-art batches are now wired into runtime config:
  - 10 accepted algorithm illustrations plus contact sheet and validation manifest
  - 10 accepted product manager illustrations plus contact sheet and validation manifest
  - `Tools/build_config.mjs` maps the product manager `card_pm_change_wording` card to the generated `pm_change_request` asset slug
- All 16 EnemyDef rows now have visible runtime battle art:
  - existing chapter 1 enemy/Boss scene art stays in place
  - chapter 2/3 enemies, later elites, `boss_mutant_hr`, and `boss_mutant_ceo` now use the generated enemy portrait final set
- Main menu has been upgraded into a polished first-screen UI:
  - full-screen generated office background with dark readability overlay
  - animated office-grid atmosphere, elevator-lobby route panel, title, subtitle, playable-content counters, current suspend-save status
  - dynamic building broadcast strip and KPI risk chip give the opening screen a live game-menu feel
  - rotating class spotlight panel uses existing profession keyart, class colors, resource labels, live card-pool counts, and clickable class tabs
  - right-side action panel for new run, continue, meta progression, and exit
  - bottom career dossier strip using existing class portrait assets, class colors, core resource labels, difficulty, and live card-pool counts
  - dynamic nodes now expose spec-aligned names such as `Root`, `TitlePanel`, `ClassSpotlightPanel`, `PrimaryActions`, `NewGameButton`, `ContinueButton`, `MetaButton`, and `ExitButton`
  - the first screen includes a compact duty board for playable career count, suspend-save presence, and current meta currency
  - continue action text and tooltip now reflect whether a valid suspend save exists
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
- Algorithm starter cards now work as designed resource-management tools instead of generic skill fillers:
  - `card_algo_linear_probe` deals starter damage and gains compute
  - `card_algo_complexity_compress` grants block and lowers complexity
  - `card_algo_heuristic_search` draws a card and gains compute without generic block
  - `card_algo_local_opt` lowers complexity and discounts the next card
- Algorithm `card_algo_complexity_burst` now works as the designed complexity-scaling attack:
  - generated config gives it a data-driven `complexity_multiplier` instead of the generic attack-plus-compute filler
  - runtime damage reads the higher of complexity resource/status stacks and adds that scaled bonus without consuming complexity
  - the card now rewards high-complexity setup while preserving complexity for later pressure/compression decisions
- Algorithm `card_algo_big_o_compress` now works as the designed complexity conversion skill:
  - generated config uses `compress_complexity` with data-driven conversion caps and compute/block ratios
  - runtime consumes complexity from resource/status stacks, then directly grants compute and block without re-raising complexity from the conversion
  - block gain still uses the normal block path so block relics remain compatible
- Algorithm `card_algo_pruning` now works as the designed pruning tempo skill:
  - generated config lowers complexity and applies the existing hidden `cost_reduction` status instead of generic block filler
  - the next non-X card receives the discount in both UI-facing cost preview and play validation
  - the discount is consumed when that next card resolves, keeping the existing card-cost hook path shared with Redis warmup
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
- Product manager `card_pm_priority_shuffle` now works as the designed starter priority tool:
  - generated config targets a selected enemy and uses `shuffle_priority` instead of default self-target skill filler
  - runtime grants block, promotes the selected target to the highest priority, and demotes other live enemies to low priority
  - the product manager priority resource display is recomputed from enemy priority stacks, so stale priority no longer controls follow-up attacks
- Product manager `card_pm_priority_top` now works as the designed priority-control tool:
  - generated config targets a selected enemy and uses `set_priority_top` instead of generic block/priority filler
  - runtime raises the selected target to a configured top priority and clears old priority from other live enemies
  - the product manager priority resource display is recomputed from enemy priority stacks, so follow-up priority attacks route to the newly topped target
- Product manager starter/control cards now have dedicated control behavior:
  - `card_pm_change_wording` lowers the selected target's attack intent instead of granting generic block
  - `card_pm_meeting_minutes` draws a card and stores hidden `meeting_minutes_boost` for the next control card
  - `card_pm_revision_notice` applies selected-target `requirement_change`, with meeting-minutes boost adding extra stacks
- Product manager high-pressure intent control has dedicated effects:
  - `card_pm_delay_meeting` now stores a selected target's high attack intent for next turn and replaces the current action with a low-yield block intent
  - `card_pm_milestone_split` now converts a selected target's high single attack into configured multi-hit lower-amount actions
  - `BattleService` resolves delayed enemy intents before random intent rolls, so the postponed action reliably returns next turn
- Product manager `requirement_change` now has live enemy-action rewriting:
  - `StatusDef.params` configures intent amount reduction and per-action stack consumption.
  - before affected enemies act, attack / multi-attack / block / debuff intent amounts are reduced.
  - consumed marks reduce both the enemy status stack and the product manager `requirement_change_marks` resource display.
- Product manager `relic_pm_meeting_room_claim` now exists and implements the Brief's "会议室占用权" relic:
  - generated config adds it as a product-manager uncommon relic with an existing meeting-room icon.
  - each player turn, the first applied `requirement_change` gains 1 extra stack and syncs the product manager resource display.
- Product manager `card_pm_scope_spread` now implements the Brief's "范围蔓延" power:
  - generated config applies a new `scope_spread` self status instead of the generic priority placeholder.
  - while active, each `requirement_change` applied to one enemy also adds a configured spread stack to another live enemy.
  - spread marks sync the product manager `requirement_change_marks` resource display and are removable by enemy boon-cleanse effects.
- Automated meta-progression coverage now verifies all six global workstation upgrades through their live runtime paths:
  - `meta_chair`, `meta_coffee_beans`, `meta_privacy_screen`, and `meta_hard_drive` at run start
  - `meta_nap_bed` at rest recovery
  - `meta_canteen_card` at first shop purchase
  - workstation purchase cost/level validation and career-unlock purchase rejection
- `EffectExecutor.move_card` now performs real battle pile movement between hand, draw, discard, and exhaust piles, including optional named-card selection and default top-card movement.
- `EffectExecutor` now executes run-state reward/deck effects directly for `add_random_card`, `add_random_relic`, `upgrade_card`, and `remove_card`, so these no longer degrade to placeholder logs outside event handling.
- Card illustration presentation now uses `CardDef.art_path` in reusable UI card buttons for battle hands, reward choices, shop stock, and shop removal picks.
- `card_frontend_component_reuse` now has a generated P0 card illustration wired through `Tools/build_config.mjs`, Luban CSV/JSON output, and runtime config.
- The first programmer shared P0 card-art batch is now wired into runtime config:
  - 12 accepted shared card illustrations plus contact sheet and validation manifest.
  - Matching `card_illust_shared_*_v1/final.png` assets are auto-wired into `CardDef.art_path` through the existing config build pipeline.
- `Tools/build_config.mjs` now auto-wires matching `Resources/Art/Generated/P0/cards/card_illust_<card_id>_v1/final.png` assets into `CardDef.art_path`; current generated config exposes 61 card illustrations.
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
- Godot test runner now checks every EnemyDef has a configured and loadable `art_path`.
- Godot test runner now checks `api_gateway` config, `card_backend_api_gateway` generated effect, status application, round-start block, and service-threshold draw.
- Godot test runner now checks `redis_warmup` / `cost_reduction` config, `card_backend_redis_warmup` generated effect, cache gain, same-turn no-discount behavior, next-round cost discount, UI-facing cost preview, play validation, and discount consumption.
- Godot test runner now checks `request_queue` config, `card_backend_message_queue` generated effect, request resource/status sync, round-end all-enemy damage, and request consumption.
- Godot test runner now checks `sharding` config, `card_backend_sharding` generated effect, status application, first-cache bonus, once-per-turn gating, and next-turn reset.
- Godot test runner now checks `card_backend_traffic_shaping` generated pressure-conversion params, block gain, and live conversion from `damage_taken_this_turn` into cache.
- Godot test runner now checks `card_backend_circuit_breaker` generated service/pressure params, service-scaled block, service cache gain, unchanged service count, and normal card-cost charge.
- Godot test runner now checks `card_backend_service_degrade` generated mitigation params, attack intent reduction, multi-attack intent reduction, service-scaled block, cache preservation, unchanged service count, and zero-cost play.
- Godot test runner now checks `card_backend_trace_chain` generated tutor effect, draw-pile service-card search, non-service preservation, card-cost charge, and discard-pile exclusion.
- Godot test runner now checks the live `service_online` round-start and round-end hooks.
- Godot test runner now checks frontend `style_layer` damage bonus and consumption from both resource-sourced and status-sourced stacks.
- Godot test runner now checks frontend `card_frontend_flex_layout` generated block/component effects, live block gain, component generation, no style-layer generation, and cost charge.
- Godot test runner now checks frontend `card_frontend_slice_sprint` generated draw/style-layer effects, live draw, style-layer generation, no component generation, no block gain, and zero-cost behavior.
- Godot test runner now checks frontend `card_frontend_hotfix_style` generated hidden status, damage-hook config, next-attack virtual style-layer damage, status consumption, no immediate block/style gain, and turn-end expiry.
- Godot test runner now checks frontend `card_frontend_component_reuse` generated params, copy-on-existing-component behavior, draw-on-success behavior, and no-copy/no-draw behavior without an existing component.
- Godot test runner now checks frontend `card_frontend_pixel_align` generated component-bonus params, base block without components, bonus block with components, no component generation, no draw, and component preservation.
- Godot test runner now checks frontend `card_frontend_compat_patch` generated cleanse/preserve effects, hidden status hooks, debuff cleansing, style bonus damage with preserved style layers, and turn-end expiry.
- Godot test runner now checks `state_boost` config, `card_frontend_state_boost` generated effect, fourth-card style-layer gain, immediate damage boost, and style-layer consumption.
- Godot test runner now checks `vue_suite` config, `card_frontend_vue_suite` generated effect, status application, and round-start component generation.
- Godot test runner now checks `card_frontend_motion_overload` generated play-count scaling params and live damage based on the current turn's played-card count.
- Godot test runner now checks `card_frontend_first_screen` generated hidden status, two separate next-card discounts, per-card stack consumption, no third-card discount, and turn-end expiry.
- Godot test runner now checks `card_frontend_crash_animation` generated style-layer finisher params, style-layer-to-extra-hit conversion, and full style-layer consumption.
- Godot test runner now checks tester `card_tester_smoke_test` generated block/observe effects, no-Diff behavior, live next-intent preview storage, readable preview text, and preview consumption on intent refresh.
- Godot test runner now checks tester `card_tester_auto_regression` generated status hook/params, status application, round-end Bug trigger damage, and case/resource sync.
- Godot test runner now checks tester `card_tester_boundary_check` selected targeting, generated `boundary_check` params, low-HP bonus, high-attack bonus, base no-boundary behavior, and case resource sync.
- Godot test runner now checks tester `card_tester_bug_upgrade` selected targeting, generated `upgrade_bug` effect, block gain, existing-Bug upgrade, resource sync, intent weakening, and no-Bug no-op behavior.
- Godot test runner now checks tester `card_tester_case_matrix` generated status hook/params, status application, first-case bonus, once-per-turn gating, and next-turn reset.
- Godot test runner now checks tester `card_tester_repro_steps` generated selected-target Bug injection, selected enemy application, unselected enemy preservation, starter relic case trigger, and Bug/case resource sync.
- Godot test runner now checks tester `card_tester_regression_confirm` selected targeting, generated `confirm_regression` effect, case-gated Diff/resource sync, draw, and no-case no-op behavior.
- Godot test runner now checks tester `card_tester_92_bugs` selected targeting, generated multi-hit `inject_bug` params, multi-Bug injection, Diff consumption across hits, resource sync, and per-Bug intent weakening.
- Godot test runner now checks tester `card_tester_report_lock` generated params, Bug/Diff damage-hook declarations, and real combat damage scaling from Bug, case, and Diff stacks.
- Godot test runner now checks tester `Diff` hook declaration, extra Bug injection, Diff consumption, `diff_tags` resource sync, and final intent reduction.
- Godot test runner now checks backend `cache` damage-hook declaration, `card_backend_flush_all` generated params, cache-scaled damage, and cache consumption.
- Godot test runner now checks frontend `card_frontend_pixel_tap` generated played-card threshold bonus plus live base damage and post-card light damage.
- Godot test runner now checks algorithm `compute` damage-hook declaration, X-finisher damage scaling, compute consumption, and local-cluster energy refund.
- Godot test runner now checks all four algorithm starter cards for generated effects and live combat behavior: linear damage/compute, complexity compression, heuristic draw/compute, and local-optimum next-card discount.
- Godot test runner now checks algorithm `card_algo_complexity_burst` generated complexity-scaling params, live complexity-based bonus damage, no generic compute gain, and preserved complexity.
- Godot test runner now checks algorithm `card_algo_big_o_compress` generated conversion params, live complexity consumption, compute conversion, block conversion, and card-cost charge.
- Godot test runner now checks algorithm `card_algo_pruning` generated complexity-reduction/discount params, live complexity reduction, discounted next-card preview/play validation, reduced energy charge, and discount consumption.
- Godot test runner now checks `relic_gpu_training_card` config, algorithm ownership, compute trigger declaration, first compute bonus, and one-shot behavior.
- Godot test runner now checks `complexity` status params, compute-to-complexity gain, GPU bonus complexity gain, high-complexity round-start pressure, and resource/status no-double-count behavior.
- Godot test runner now checks product manager priority target routing, including ignored low-priority selected targets and requirement-change marking on the resolved target.
- Godot test runner now checks product manager `card_pm_priority_shuffle` generated target/effects, block gain, selected-target promotion, other-target demotion, resource recompute, and follow-up priority-attack routing.
- Godot test runner now checks product manager `card_pm_priority_top` generated target/effects, selected target priority replacement, old priority clearing, resource recompute, draw, and follow-up priority-attack routing.
- Godot test runner now checks product manager `card_pm_change_wording`, `card_pm_meeting_minutes`, and `card_pm_revision_notice` generated effects, selected targeting, no-generic-block behavior, meeting-minutes boost bonuses, consumption, and resource sync.
- Godot test runner now checks product manager `card_pm_delay_meeting` and `card_pm_milestone_split` generated effects, selected targeting, no-generic-block behavior, forced next-turn delayed intent, and high-attack split intent output.
- Godot test runner now checks product manager `requirement_change` status params, enemy-action intent reduction, stack consumption, and resource sync after consumption.
- Godot test runner now checks `relic_pm_meeting_room_claim` config, first requirement-change boost, once-per-turn gating, next-turn reset, and boosted resource sync.
- Godot test runner now checks `scope_spread` config, `card_pm_scope_spread` generated effect, requirement-change spread to another enemy, and spread resource sync.
- Godot test runner now checks career-tree labels, HR non-playable status, and milestone progress text.
- Godot test runner now checks global workstation upgrade purchases plus run-start, rest, and shop effects for every implemented upgrade.
- Godot test runner now checks `move_card` named-card and top-card movement across combat piles.
- Godot test runner now checks `EffectExecutor` deck/relic reward effects update `RunState` and active battle upgrade state.
- Godot test runner now checks configured card art paths load, including `card_frontend_component_reuse`.
- Godot test runner now checks bulk card-art auto-wiring through an existing backend card illustration and a minimum configured-card-art count.
- Godot test runner now explicitly checks all 10 frontend P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot test runner now explicitly checks all 10 tester P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot test runner now explicitly checks all 10 algorithm and all 10 product manager P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot test runner now explicitly checks all 12 programmer shared P0 card illustrations are configured through `CardDef.art_path` and load successfully.
- Godot test runner now verifies the main menu scene loads, key source-declared UI sections exist, the four spec-required action buttons are configured, and all main-menu background/keyart assets load.
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
- Remaining card illustration gaps, if pursued, are outside the generated P0 representative/shared batches and belong to later non-representative or expansion card-art polish.
