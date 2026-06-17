class_name MetaProgressionService
extends RefCounted

var save_service: SaveService
var config_service: ConfigService
var meta_state: Dictionary = {}

func setup(p_save_service: SaveService, p_config_service: ConfigService) -> void:
	save_service = p_save_service
	config_service = p_config_service
	meta_state = save_service.load_meta(default_meta_state())
	_normalize_meta_state()

func default_meta_state() -> Dictionary:
	return {
		"owned_discomfort_currency": 0,
		"unlocked_class_ids": ["backend"],
		"meta_upgrade_levels": {},
		"career_milestones": {},
		"highest_floor_reached": 1,
		"defeated_boss_records": [],
		"settings": {
			"fullscreen": false,
			"master_volume": 100,
		},
	}

func update_setting(key: String, value) -> void:
	var settings: Dictionary = meta_state.get("settings", {})
	settings[key] = value
	meta_state["settings"] = settings
	save_service.save_meta(meta_state)

func _normalize_meta_state() -> void:
	var defaults := default_meta_state()
	for key in defaults.keys():
		if not meta_state.has(key):
			meta_state[key] = defaults[key]
	var settings: Dictionary = meta_state.get("settings", {})
	var default_settings: Dictionary = defaults.get("settings", {})
	for key in default_settings.keys():
		if not settings.has(key):
			settings[key] = default_settings[key]
	settings["fullscreen"] = bool(settings.get("fullscreen", false))
	settings["master_volume"] = clampi(int(settings.get("master_volume", 100)), 0, 100)
	meta_state["settings"] = settings

func is_class_unlocked(class_id: String) -> bool:
	return meta_state.get("unlocked_class_ids", []).has(class_id)

func is_class_playable(class_id: String) -> bool:
	var cls: Dictionary = config_service.get_def("classes", class_id)
	return is_class_unlocked(class_id) and bool(cls.get("enabled_in_first_playable", false))

func class_unlock_label(cls: Dictionary) -> String:
	var class_id := String(cls.get("id", ""))
	var enabled := bool(cls.get("enabled_in_first_playable", false))
	if class_id == "hr" and not enabled:
		return "扩展预留：击败变异HR后开放完整战斗系统"
	if not enabled:
		return "后端全链路优先：该职业暂锁定占位"
	match String(cls.get("unlock_type", "")):
		"default":
			return "默认开放"
		"boss_defeated":
			return "击败 Boss：%s" % _boss_name(String(cls.get("unlock_param", "")))
		"elite_wins":
			return "累计击败精英：%d 场" % int(cls.get("unlock_param", "0"))
		"event_count":
			return "累计解决随机事件：%d 次" % int(cls.get("unlock_param", "0"))
		"reach_floor":
			return "到达顶层"
		_:
			return "解锁条件未配置"

func class_unlock_progress(cls: Dictionary) -> String:
	if not bool(cls.get("enabled_in_first_playable", false)):
		return "占位"
	var milestones: Dictionary = meta_state.get("career_milestones", {})
	var bosses: Array = meta_state.get("defeated_boss_records", [])
	match String(cls.get("unlock_type", "")):
		"default":
			return "已满足"
		"boss_defeated":
			var boss_id := String(cls.get("unlock_param", ""))
			return "已击败" if bosses.has(boss_id) else "未击败"
		"elite_wins":
			var required_elites := int(cls.get("unlock_param", "0"))
			return "%d/%d" % [int(milestones.get("elite_wins", 0)), required_elites]
		"event_count":
			var required_events := int(cls.get("unlock_param", "0"))
			return "%d/%d" % [int(milestones.get("events_resolved", 0)), required_events]
		"reach_floor":
			return "%d/18F" % int(milestones.get("highest_floor_reached", meta_state.get("highest_floor_reached", 1)))
		_:
			return "-"

func class_availability_label(cls: Dictionary) -> String:
	var class_id := String(cls.get("id", ""))
	if is_class_playable(class_id):
		return "可出战"
	if not bool(cls.get("enabled_in_first_playable", false)):
		return "扩展占位" if class_id == "hr" else "锁定占位"
	if bool(cls.get("enabled_in_first_playable", false)):
		return "未解锁"
	return "未开放"

func get_upgrade_level(upgrade_id: String) -> int:
	return int(meta_state.get("meta_upgrade_levels", {}).get(upgrade_id, 0))

func buy_upgrade(upgrade_id: String) -> bool:
	var upgrade: Dictionary = config_service.get_def("meta_upgrades", upgrade_id)
	if upgrade.is_empty() or upgrade.get("type", "") != "global_upgrade":
		return false
	var level := get_upgrade_level(upgrade_id)
	var max_level := int(upgrade.get("max_level", 0))
	if level >= max_level:
		return false
	var costs: Array = upgrade.get("cost_curve", [])
	var cost := int(costs[min(level, costs.size() - 1)])
	if int(meta_state.get("owned_discomfort_currency", 0)) < cost:
		return false
	meta_state["owned_discomfort_currency"] = int(meta_state.get("owned_discomfort_currency", 0)) - cost
	var levels: Dictionary = meta_state.get("meta_upgrade_levels", {})
	levels[upgrade_id] = level + 1
	meta_state["meta_upgrade_levels"] = levels
	save_service.save_meta(meta_state)
	return true

func apply_run_start_bonuses(player_state: Dictionary) -> void:
	var chair := get_upgrade_level("meta_chair")
	player_state["max_spirit"] = int(player_state.get("max_spirit", 72)) + chair * 4
	player_state["current_spirit"] = int(player_state.get("current_spirit", player_state["max_spirit"])) + chair * 4
	var coffee := get_upgrade_level("meta_coffee_beans")
	player_state["base_energy"] = int(player_state.get("base_energy", 3)) + (1 if coffee >= 2 else 0)
	var privacy := get_upgrade_level("meta_privacy_screen")
	player_state["opening_block_bonus"] = int(player_state.get("opening_block_bonus", 0)) + privacy * 2
	var hard_drive := get_upgrade_level("meta_hard_drive")
	player_state["opening_draw_bonus"] = int(player_state.get("opening_draw_bonus", 0)) + hard_drive

func settle_run(run_state: Dictionary, victory: bool) -> int:
	if run_state.get("run_flags", {}).get("settled", false):
		return int(run_state.get("settlement_state", {}).get("earned_currency", 0))
	var reached_floor := int(run_state.get("current_floor", 1))
	var boss_count := int(run_state.get("defeated_boss_ids", []).size())
	var earned := int(reached_floor * 2 + boss_count * 35 + (80 if victory else 0))
	meta_state["owned_discomfort_currency"] = int(meta_state.get("owned_discomfort_currency", 0)) + earned
	meta_state["highest_floor_reached"] = max(int(meta_state.get("highest_floor_reached", 1)), reached_floor)
	var milestones: Dictionary = meta_state.get("career_milestones", {})
	var counters: Dictionary = run_state.get("run_counters", {})
	for key in counters.keys():
		milestones[key] = int(milestones.get(key, 0)) + int(counters.get(key, 0))
	milestones["highest_floor_reached"] = max(int(milestones.get("highest_floor_reached", 1)), reached_floor)
	meta_state["career_milestones"] = milestones
	for boss_id in run_state.get("defeated_boss_ids", []):
		var records: Array = meta_state.get("defeated_boss_records", [])
		if not records.has(boss_id):
			records.append(boss_id)
		meta_state["defeated_boss_records"] = records
	_unlock_available_careers()
	var flags: Dictionary = run_state.get("run_flags", {})
	flags["settled"] = true
	run_state["run_flags"] = flags
	run_state["settlement_state"] = {
		"victory": victory,
		"earned_currency": earned,
		"highest_floor": reached_floor,
		"boss_count": boss_count,
		"battle_count": int(counters.get("battles_won", 0)),
		"elite_count": int(counters.get("elite_wins", 0)),
		"event_count": int(counters.get("events_resolved", 0)),
		"shop_count": int(counters.get("shops_visited", 0)),
		"rest_count": int(counters.get("rests_used", 0)),
		"enemy_count": int(counters.get("enemies_defeated", 0)),
		"total_currency_after": int(meta_state.get("owned_discomfort_currency", 0)),
	}
	save_service.save_meta(meta_state)
	return earned

func _boss_name(boss_id: String) -> String:
	if boss_id.is_empty():
		return "指定 Boss"
	var enemy: Dictionary = config_service.get_def("enemies", boss_id)
	return String(enemy.get("name", boss_id))

func _unlock_available_careers() -> void:
	var unlocked: Array = meta_state.get("unlocked_class_ids", [])
	var milestones: Dictionary = meta_state.get("career_milestones", {})
	var bosses: Array = meta_state.get("defeated_boss_records", [])
	for cls in config_service.all_defs("classes"):
		var class_id := String(cls.get("id", ""))
		if not bool(cls.get("enabled_in_first_playable", false)):
			continue
		if unlocked.has(class_id):
			continue
		if _is_unlock_condition_met(cls, milestones, bosses):
			unlocked.append(class_id)
	meta_state["unlocked_class_ids"] = unlocked

func _is_unlock_condition_met(cls: Dictionary, milestones: Dictionary, bosses: Array) -> bool:
	match String(cls.get("unlock_type", "")):
		"default":
			return true
		"boss_defeated":
			return bosses.has(String(cls.get("unlock_param", "")))
		"elite_wins":
			return int(milestones.get("elite_wins", 0)) >= int(cls.get("unlock_param", "0"))
		"event_count":
			return int(milestones.get("events_resolved", 0)) >= int(cls.get("unlock_param", "0"))
		"reach_floor":
			return int(milestones.get("highest_floor_reached", 1)) >= 18
		_:
			return false
