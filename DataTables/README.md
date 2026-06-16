# withgai DataTables

This directory is the project-local Luban source workspace.

- `Datas/*.csv` are Luban-compatible source tables generated from the current design brief.
- `Datas/__tables__.csv` declares all exported tables for Luban 4.
- `Defines/withgai.xml` declares shared nested value types used by JSON-format cells.
- `EffectGroupDef`, `EffectEntryDef`, `EnemyIntentGroupDef`, `RewardProfileDef`, and `ShopPoolDef` are kept as separate generated source tables so runtime data has no hardcoded gameplay pools.
- `../Data/Generated/Config/game_config.json` is the runtime data consumed by Godot.
- `gen_client.sh` uses `Tools/Luban/Luban.dll` when present, or a `LUBAN_DLL` override.
- Real Luban generation emits per-table JSON plus `Scripts/Generated/Config/schema.gd`, then `Tools/pack_luban_config.mjs` repacks those tables into the existing runtime `game_config.json`.

This workstation has a user-local .NET SDK 8 install at `~/.dotnet`. If `dotnet` on `PATH` is older, `gen_client.sh` will use `~/.dotnet/dotnet` automatically.
