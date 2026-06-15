class_name RunSession
extends RefCounted

var config_service: ConfigService
var map_service: MapService
var meta_service: MetaProgressionService
var run_state: Dictionary = {}

func setup(p_config_service: ConfigService, p_map_service: MapService, p_meta_service: MetaProgressionService) -> void:
	config_service = p_config_service
	map_service = p_map_service
	meta_service = p_meta_service

func has_active_run() -> bool:
	return not run_state.is_empty()

func clear() -> void:
	run_state = {}

func create_new_run(class_id: String) -> Dictionary:
	var cls: Dictionary = config_service.get_def("classes", class_id)
	var player_state := {
		"max_spirit": 72,
		"current_spirit": 72,
		"base_energy": 3,
		"deck_card_ids": cls.get("starter_deck", []).duplicate(true),
		"removed_card_ids": [],
		"upgraded_card_instance_ids": [],
		"class_resource_persistent_state": {},
		"opening_draw_bonus": 0,
		"opening_block_bonus": 0,
	}
	meta_service.apply_run_start_bonuses(player_state)
	run_state = {
		"run_id": "run_%d" % Time.get_unix_time_from_system(),
		"selected_class_id": class_id,
		"current_chapter": 1,
		"current_floor": 1,
		"current_node_id": "",
		"rng_seed": randi(),
		"map_state": {},
		"deck_state": {
			"master_deck": cls.get("starter_deck", []).duplicate(true),
			"temporary_added_cards": [],
			"removed_cards": [],
			"upgraded_cards": [],
		},
		"player_state": player_state,
		"owned_relic_ids": [cls.get("starter_relic_id", "")],
		"currency_perf_points": 0,
		"visited_node_ids": [],
		"event_history_ids": [],
		"defeated_boss_ids": [],
		"run_counters": {
			"battles_won": 0,
			"elite_wins": 0,
			"events_resolved": 0,
			"shops_visited": 0,
			"rests_used": 0,
			"enemies_defeated": 0,
		},
		"pending_reward_state": {},
		"active_battle_state": {},
		"current_scene_tag": "map",
		"run_flags": {},
		"shop_state": {},
		"event_state": {},
	}
	map_service.generate_chapter(run_state, 1)
	return run_state

func restore_from_suspend(save_state: Dictionary) -> bool:
	var restored: Dictionary = save_state.get("serialized_run_state", {})
	if restored.is_empty():
		return false
	run_state = restored
	return true
