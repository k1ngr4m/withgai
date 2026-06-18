import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const configDir = path.join(root, "Data", "Generated", "Config");
const PROJECT_VERSION = "0.1.0001";

const tables = [
  ["ClassDef", "classes"],
  ["CardDef", "cards"],
  ["RelicDef", "relics"],
  ["EnemyDef", "enemies"],
  ["EncounterDef", "encounters"],
  ["MapNodeDef", "map_nodes"],
  ["EventDef", "events"],
  ["InitialBoostDef", "initial_boosts"],
  ["StatusDef", "statuses"],
  ["MetaUpgradeDef", "meta_upgrades"],
  ["EffectGroupDef", "effect_groups"],
  ["EffectEntryDef", "effect_entries"],
  ["EnemyIntentGroupDef", "intent_groups"],
  ["PhaseGroupDef", "phase_groups"],
  ["RewardProfileDef", "reward_profiles"],
  ["ShopPoolDef", "shop_pools"],
];

function readRows(tableName) {
  const file = path.join(configDir, `${tableName}.json`);
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function indexById(rows) {
  return Object.fromEntries(rows.map((row) => [row.id, row]));
}

const config = { version: PROJECT_VERSION };
for (const [tableName, key] of tables) {
  config[key] = indexById(readRows(tableName));
}

for (const group of Object.values(config.effect_groups)) {
  group.entries = (group.entry_ids ?? [])
    .map((entryId) => config.effect_entries[entryId])
    .filter(Boolean)
    .map((entry) => ({
      effect_type: entry.effect_type,
      target_type: entry.target_type,
      params: entry.params ?? {},
    }));
}

fs.writeFileSync(path.join(configDir, "game_config.json"), `${JSON.stringify(config, null, 2)}\n`);
