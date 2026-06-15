# withgai DataTables

This directory is the project-local Luban source workspace.

- `Datas/*.csv` are Luban-compatible source tables generated from the current design brief.
- `EffectGroupDef`, `EffectEntryDef`, `EnemyIntentGroupDef`, `RewardProfileDef`, and `ShopPoolDef` are kept as separate generated source tables so runtime data has no hardcoded gameplay pools.
- `../Data/Generated/Config/game_config.json` is the runtime data consumed by Godot.
- `gen_client.sh` expects a Luban 4.x `Luban.dll` path through `LUBAN_DLL`.

The current workstation has .NET SDK 7.0.200, while Luban 4.x expects .NET SDK 8.0 or newer. Until .NET 8 and Luban are installed, use `node Tools/build_config.mjs` to refresh the checked-in generated JSON from the same data source.
