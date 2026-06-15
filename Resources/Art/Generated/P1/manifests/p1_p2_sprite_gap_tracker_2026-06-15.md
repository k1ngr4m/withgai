# p1_p2_sprite_gap_tracker_2026-06-15

Source guide: [04_ASSET_PROMPTS.md](/Users/linyiming/Projects/GodotProjects/withgai/Resources/Docs/04_ASSET_PROMPTS.md)

Scope: P1/P2 `hero_action_bundle` sprite deliverables from sections 5.4, 5.8, 5.12, 5.16, 5.20, and 5.24.

## Status

| Priority | Resource | Actions | Status | Notes |
| --- | --- | --- | --- | --- |
| P1 | `char_backend_sprite_bundle` | `idle`, `run`, `skill_cast`, `hurt` | Completed | See `batch_2026-06-15_p1_backend_sprite_bundle_01.md`. |
| P1 | `char_frontend_sprite_bundle` | `idle`, `run`, `skill_cast`, `attack` | Completed | See `batch_2026-06-15_p1_frontend_sprite_bundle_01.md`. |
| P1 | `char_tester_sprite_bundle` | `idle`, `run`, `debuff_cast`, `hurt` | Completed | See `batch_2026-06-15_p1_tester_sprite_bundle_01.md`. |
| P1 | `char_algorithm_sprite_bundle` | `idle`, `run`, `charge`, `cast` | Completed | See `batch_2026-06-15_p1_algorithm_sprite_bundle_01.md`. |
| P1 | `char_product_manager_sprite_bundle` | `idle`, `run`, `command_cast`, `hurt` | Completed | See `batch_2026-06-15_p1_product_manager_sprite_bundle_01.md`. |
| P2 | `char_hr_sprite_bundle` | `idle`, `run`, `execute_cast`, `hurt` | Pending | No P0 HR keyart exists yet; generate directly from section 5.24 or create HR keyart first. |

## Batch Rules

- Generate one action per raw multi-row sheet.
- Use `2x2` for four-frame body actions and `2x3` for six-frame cast/charge actions.
- Keep hero body sheets body-only; split wide projectiles, impact bursts, long trails, large UI panels, and detached FX into separate future assets.
- Require solid `#FF00FF` raw backgrounds and empty `edge_touch_frames` before accepting a sheet.
- Use accepted idle/run sheets as direct sprite references for later actions within the same bundle when available.
