extends SceneTree

const ConfigServiceScript := preload("res://Scripts/Services/ConfigService.gd")
const SaveServiceScript := preload("res://Scripts/Services/SaveService.gd")
const MetaProgressionServiceScript := preload("res://Scripts/Services/MetaProgressionService.gd")
const MapServiceScript := preload("res://Scripts/Services/MapService.gd")
const RunSessionScript := preload("res://Scripts/Services/RunSession.gd")
const ContentResolverScript := preload("res://Scripts/Services/ContentResolver.gd")
const EffectExecutorScript := preload("res://Scripts/Services/EffectExecutor.gd")
const BattleServiceScript := preload("res://Scripts/Services/BattleService.gd")
const RewardServiceScript := preload("res://Scripts/Services/RewardService.gd")

var failed := false

func _init() -> void:
	var config = ConfigServiceScript.new()
	config.load_config()
	_check(config.get_table("classes").size() >= 6, "classes loaded")
	_check(config.get_table("cards").size() >= 162, "cards loaded")
	_check(config.get_table("effect_groups").size() >= config.get_table("cards").size(), "effect groups loaded")
	_check(config.get_table("effect_entries").size() >= config.get_table("cards").size(), "effect entries loaded")
	var content = ContentResolverScript.new()
	content.call("setup", config)
	var save = SaveServiceScript.new()
	var meta = MetaProgressionServiceScript.new()
	meta.call("setup", save, config)
	var map = MapServiceScript.new()
	map.call("setup", config)
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var reward_service = RewardServiceScript.new()
	reward_service.call("setup", content, map, meta)
	_validate_config_references(config, content)
	for class_id in ["backend", "frontend", "tester", "algorithm", "product_manager"]:
		var run := run_session.create_new_run(class_id)
		_check(run.get("deck_state", {}).get("master_deck", []).size() == 10, "%s starter deck" % class_id)
		_check(run.get("map_state", {}).get("floors", []).size() == 6, "%s chapter map" % class_id)
		_check(run.get("map_state", {}).get("available_next_nodes", []).size() > 0, "%s available nodes" % class_id)
		_validate_class_resources(class_id)
		_validate_map_constraints(run, "%s map constraints" % class_id)
		_validate_battle(class_id, config, content, map, meta, reward_service)
	_validate_combat_mechanics(config, content, map, meta)
	_validate_enemy_intent_actions(config, content, map, meta)
	_validate_enemy_phase_scripts(config, content, map, meta)
	_validate_shop_event_rest(config, content, map, meta, reward_service)
	_validate_reward_economy(config, map, meta, reward_service)
	_validate_save_roundtrip(config, map, meta, save)
	_validate_meta_settlement(config, map, meta)
	_validate_meta_upgrades(config, map, meta, reward_service)
	_validate_boss_progression(config, map, meta, reward_service)
	print("TEST_RESULT: %s" % ("FAILED" if failed else "PASSED"))
	quit(1 if failed else 0)

func _validate_config_references(config, content) -> void:
	_check(not config.get_def("classes", "hr").get("enabled_in_first_playable", true), "hr remains placeholder")
	_check(content.cards_for_run_class("hr", true).is_empty(), "hr excluded from run card pool")
	_check(not content.reward_profile("reward_default").is_empty(), "default reward profile exists")
	_check(not content.shop_pool("shop_default").is_empty(), "default shop pool exists")
	for class_id in ["backend", "frontend", "tester", "algorithm", "product_manager"]:
		var cls: Dictionary = content.class_def(class_id)
		_check(content.is_run_class_enabled(class_id), "%s enabled as run class" % class_id)
		_check(not content.relic_def(cls.get("starter_relic_id", "")).is_empty(), "%s starter relic resolves" % class_id)
		for card_id in cls.get("starter_deck", []):
			_check(not content.card_def(card_id).is_empty(), "%s starter card resolves" % card_id)
		var pool: Array = content.cards_for_run_class(class_id, true)
		_check(pool.size() >= 30, "%s content pool has cards" % class_id)
		var has_hr_card := false
		for card in pool:
			if String(card.get("id", "")).begins_with("card_hr_"):
				has_hr_card = true
		_check(not has_hr_card, "%s pool excludes hr cards" % class_id)
	var enabled_cards_missing_group := 0
	var enabled_cards_missing_entries := 0
	for card in config.all_defs("cards"):
		if not card.get("enabled_in_first_playable", false):
			continue
		var group_id := String(card.get("effect_group_id", ""))
		if group_id.is_empty():
			enabled_cards_missing_group += 1
		if content.effect_entries(group_id).is_empty():
			enabled_cards_missing_entries += 1
	_check(enabled_cards_missing_group == 0, "enabled cards have effect group ids")
	_check(enabled_cards_missing_entries == 0, "enabled card effect entries resolve")
	var orphan_effect_entries := 0
	for entry in config.all_defs("effect_entries"):
		if config.get_def("effect_groups", entry.get("effect_group_id", "")).is_empty():
			orphan_effect_entries += 1
	_check(orphan_effect_entries == 0, "effect entries resolve parent groups")
	var enemies_missing_intents := 0
	var enemies_missing_rewards := 0
	var enemies_missing_art := 0
	var enemies_unloadable_art := 0
	for enemy in config.all_defs("enemies"):
		if content.intent_entries_for_enemy(enemy.get("id", "")).is_empty():
			enemies_missing_intents += 1
		if content.reward_profile(enemy.get("reward_profile_id", "")).is_empty():
			enemies_missing_rewards += 1
		var enemy_art_path := String(enemy.get("art_path", ""))
		if enemy_art_path.is_empty():
			enemies_missing_art += 1
		elif load(enemy_art_path) == null:
			enemies_unloadable_art += 1
	_check(enemies_missing_intents == 0, "enemy intent groups resolve")
	_check(enemies_missing_rewards == 0, "enemy reward profiles resolve")
	_check(enemies_missing_art == 0, "enemy art paths configured")
	_check(enemies_unloadable_art == 0, "enemy art paths load")
	var encounter_missing_enemies := 0
	for encounter in config.all_defs("encounters"):
		for enemy_id in encounter.get("enemy_ids", []):
			if content.enemy_def(enemy_id).is_empty():
				encounter_missing_enemies += 1
	_check(encounter_missing_enemies == 0, "encounter enemies resolve")
	for card_id in ["card_status_option_promise", "card_status_meeting_minutes", "card_curse_next_year_promotion"]:
		var pollution_card: Dictionary = content.card_def(card_id)
		_check(not pollution_card.is_empty(), "%s pollution card resolves" % card_id)
		_check(not content.effect_entries(pollution_card.get("effect_group_id", "")).is_empty(), "%s pollution card has effects" % card_id)
	var circuit_breaker_entries: Array = content.effect_entries(content.card_def("card_backend_circuit_breaker").get("effect_group_id", ""))
	var circuit_breaker_scales := false
	for entry in circuit_breaker_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "circuit_breaker" and int(params.get("amount", 0)) > 0 and int(params.get("service_block_amount", 0)) > 0 and int(params.get("service_cache_amount", 0)) > 0 and int(params.get("heavy_attack_threshold", 0)) > 0 and int(params.get("heavy_block_amount", 0)) > 0:
			circuit_breaker_scales = true
	_check(circuit_breaker_scales, "backend circuit breaker scales with service and heavy attack")
	var service_degrade_entries: Array = content.effect_entries(content.card_def("card_backend_service_degrade").get("effect_group_id", ""))
	var service_degrade_reduces_intent := false
	for entry in service_degrade_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "service_degrade" and int(params.get("amount", 0)) > 0 and int(params.get("block_per_service", 0)) > 0 and int(params.get("cache_if_service", 0)) > 0:
			service_degrade_reduces_intent = true
	_check(service_degrade_reduces_intent, "backend service degrade lowers damage and scales with service")
	var trace_chain_entries: Array = content.effect_entries(content.card_def("card_backend_trace_chain").get("effect_group_id", ""))
	var trace_chain_fetches_service := false
	for entry in trace_chain_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "fetch_service_card" and int(params.get("amount", 0)) > 0:
			trace_chain_fetches_service = true
	_check(trace_chain_fetches_service, "backend trace chain fetches service cards")
	var api_gateway_entries: Array = content.effect_entries(content.card_def("card_backend_api_gateway").get("effect_group_id", ""))
	var api_gateway_applies_status := false
	for entry in api_gateway_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "api_gateway":
			api_gateway_applies_status = true
	_check(api_gateway_applies_status, "backend api gateway applies api gateway status")
	var redis_entries: Array = content.effect_entries(content.card_def("card_backend_redis_warmup").get("effect_group_id", ""))
	var redis_adds_cache := false
	var redis_applies_warmup := false
	for redis_entry in redis_entries:
		var redis_entry_params: Dictionary = redis_entry.get("params", {})
		if redis_entry.get("effect_type", "") == "add_cache" and int(redis_entry_params.get("amount", 0)) >= 3:
			redis_adds_cache = true
		if redis_entry.get("effect_type", "") == "apply_status" and redis_entry_params.get("status_id", "") == "redis_warmup":
			redis_applies_warmup = true
	_check(redis_adds_cache, "backend redis warmup adds large cache")
	_check(redis_applies_warmup, "backend redis warmup applies next-turn warmup status")
	var message_queue_entries: Array = content.effect_entries(content.card_def("card_backend_message_queue").get("effect_group_id", ""))
	var message_queue_applies_requests := false
	for message_queue_entry in message_queue_entries:
		var message_queue_params: Dictionary = message_queue_entry.get("params", {})
		if message_queue_entry.get("effect_type", "") == "apply_status" and message_queue_params.get("status_id", "") == "request_queue" and int(message_queue_params.get("amount", 0)) >= 3:
			message_queue_applies_requests = true
	_check(message_queue_applies_requests, "backend message queue applies request queue")
	var sharding_entries: Array = content.effect_entries(content.card_def("card_backend_sharding").get("effect_group_id", ""))
	var sharding_applies_status := false
	for sharding_entry in sharding_entries:
		var sharding_params: Dictionary = sharding_entry.get("params", {})
		if sharding_entry.get("effect_type", "") == "apply_status" and sharding_params.get("status_id", "") == "sharding":
			sharding_applies_status = true
	_check(sharding_applies_status, "backend sharding applies sharding status")
	var traffic_entries: Array = content.effect_entries(content.card_def("card_backend_traffic_shaping").get("effect_group_id", ""))
	var traffic_shapes_damage := false
	for traffic_entry in traffic_entries:
		var traffic_params: Dictionary = traffic_entry.get("params", {})
		if traffic_entry.get("effect_type", "") == "add_cache" and bool(traffic_params.get("from_damage_taken_this_turn", false)):
			traffic_shapes_damage = true
	_check(traffic_shapes_damage, "backend traffic shaping converts damage taken to cache")
	var component_reuse_art := String(content.card_def("card_frontend_component_reuse").get("art_path", ""))
	_check(component_reuse_art.ends_with("card_illust_frontend_component_reuse_v1/final.png"), "frontend component reuse card art configured")
	var component_reuse_entries: Array = content.effect_entries(content.card_def("card_frontend_component_reuse").get("effect_group_id", ""))
	var component_reuse_requires_component := false
	for entry in component_reuse_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "add_component" and bool(params.get("requires_existing_component", false)) and bool(params.get("draw_if_success", false)):
			component_reuse_requires_component = true
	_check(component_reuse_requires_component, "frontend component reuse requires component and draws")
	var state_boost_entries: Array = content.effect_entries(content.card_def("card_frontend_state_boost").get("effect_group_id", ""))
	var state_boost_applies_status := false
	for entry in state_boost_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "state_boost":
			state_boost_applies_status = true
	_check(state_boost_applies_status, "frontend state boost applies state boost status")
	var vue_suite_entries: Array = content.effect_entries(content.card_def("card_frontend_vue_suite").get("effect_group_id", ""))
	var vue_suite_applies_status := false
	for entry in vue_suite_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "vue_suite":
			vue_suite_applies_status = true
	_check(vue_suite_applies_status, "frontend vue suite applies vue suite status")
	var motion_entries: Array = content.effect_entries(content.card_def("card_frontend_motion_overload").get("effect_group_id", ""))
	var motion_scales_with_play_count := false
	for entry in motion_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("cards_played_multiplier", 0)) > 0:
			motion_scales_with_play_count = true
	_check(motion_scales_with_play_count, "frontend motion overload scales with cards played")
	var crash_entries: Array = content.effect_entries(content.card_def("card_frontend_crash_animation").get("effect_group_id", ""))
	var crash_consumes_style_layers := false
	for entry in crash_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and bool(params.get("style_layer_hits", false)) and bool(params.get("consume_all_style_layers", false)):
			crash_consumes_style_layers = true
	_check(crash_consumes_style_layers, "frontend crash animation consumes style layers for hits")
	var circuit_breaker_art := String(content.card_def("card_backend_circuit_breaker").get("art_path", ""))
	_check(circuit_breaker_art.ends_with("card_illust_backend_circuit_breaker_v1/final.png"), "backend circuit breaker card art auto configured")
	var gpu_relic: Dictionary = content.relic_def("relic_gpu_training_card")
	_check(not gpu_relic.is_empty(), "gpu training card relic resolves")
	_check(gpu_relic.get("allowed_classes", []).has("algorithm"), "gpu training card belongs to algorithm")
	_check(gpu_relic.get("trigger_list", []).has("add_compute"), "gpu training card declares compute trigger")
	var meeting_room_relic: Dictionary = content.relic_def("relic_pm_meeting_room_claim")
	_check(not meeting_room_relic.is_empty(), "meeting room claim relic resolves")
	_check(meeting_room_relic.get("allowed_classes", []).has("product_manager"), "meeting room claim belongs to product manager")
	_check(meeting_room_relic.get("trigger_list", []).has("apply_status"), "meeting room claim declares status trigger")
	var frontend_card_art_slugs := {
		"card_frontend_component_reuse": "frontend_component_reuse",
		"card_frontend_state_boost": "frontend_state_boost",
		"card_frontend_motion_overload": "frontend_motion_overload",
		"card_frontend_hotfix_style": "frontend_hotfix_style",
		"card_frontend_pixel_align": "frontend_pixel_alignment",
		"card_frontend_compat_patch": "frontend_compat_patch",
		"card_frontend_vue_suite": "frontend_vue_suite",
		"card_frontend_css_override": "frontend_css_override",
		"card_frontend_first_screen": "frontend_first_screen_opt",
		"card_frontend_crash_animation": "frontend_crash_animation",
	}
	for card_id in frontend_card_art_slugs.keys():
		var art_path := String(content.card_def(card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % String(frontend_card_art_slugs[card_id])), "%s frontend card art configured" % card_id)
		_check(load(art_path) != null, "%s frontend card art loads" % card_id)
	var tester_card_art_slugs := [
		"card_tester_defect_log",
		"card_tester_smoke_test",
		"card_tester_repro_steps",
		"card_tester_regression_confirm",
		"card_tester_boundary_check",
		"card_tester_auto_regression",
		"card_tester_bug_upgrade",
		"card_tester_case_matrix",
		"card_tester_92_bugs",
		"card_tester_report_lock",
	]
	for card_id in tester_card_art_slugs:
		var tester_card_id := String(card_id)
		var art_path := String(content.card_def(tester_card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % tester_card_id.trim_prefix("card_")), "%s tester card art configured" % tester_card_id)
		_check(load(art_path) != null, "%s tester card art loads" % tester_card_id)
	var algorithm_card_art_slugs := [
		"card_algo_heuristic_search",
		"card_algo_dynamic_programming",
		"card_algo_complexity_burst",
		"card_algo_pruning",
		"card_algo_local_opt",
		"card_algo_big_o_compress",
		"card_algo_monte_carlo",
		"card_algo_matrix_mul",
		"card_algo_astar",
		"card_algo_global_optimum",
	]
	for card_id in algorithm_card_art_slugs:
		var algorithm_card_id := String(card_id)
		var art_path := String(content.card_def(algorithm_card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % algorithm_card_id.trim_prefix("card_")), "%s algorithm card art configured" % algorithm_card_id)
		_check(load(art_path) != null, "%s algorithm card art loads" % algorithm_card_id)
	var product_manager_card_art_slugs := {
		"card_pm_change_wording": "pm_change_request",
		"card_pm_review": "pm_review",
		"card_pm_delay_meeting": "pm_delay_meeting",
		"card_pm_priority_top": "pm_priority_top",
		"card_pm_milestone_split": "pm_milestone_split",
		"card_pm_scope_spread": "pm_scope_spread",
		"card_pm_message_align": "pm_message_align",
		"card_pm_extra_requirement": "pm_extra_requirement",
		"card_pm_align_all": "pm_align_all",
		"card_pm_roadmap": "pm_roadmap",
	}
	for card_id in product_manager_card_art_slugs.keys():
		var art_path := String(content.card_def(card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % String(product_manager_card_art_slugs[card_id])), "%s product manager card art configured" % card_id)
		_check(load(art_path) != null, "%s product manager card art loads" % card_id)
	var shared_card_art_slugs := [
		"card_shared_keyboard_smash",
		"card_shared_stapler_burst",
		"card_shared_noise_cancel",
		"card_shared_coffee_boost",
		"card_shared_toilet_break",
		"card_shared_desk_inspection",
		"card_shared_rollback",
		"card_shared_standup",
		"card_shared_clock_out",
		"card_shared_hotfix_patch",
		"card_shared_badge_throw",
		"card_shared_meeting_mute",
	]
	for card_id in shared_card_art_slugs:
		var shared_card_id := String(card_id)
		var art_path := String(content.card_def(shared_card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % shared_card_id.trim_prefix("card_")), "%s shared card art configured" % shared_card_id)
		_check(load(art_path) != null, "%s shared card art loads" % shared_card_id)
	var cards_with_art := 0
	var missing_card_art_paths := 0
	for card in config.all_defs("cards"):
		var art_path := String(card.get("art_path", ""))
		if not art_path.is_empty():
			cards_with_art += 1
			if load(art_path) == null:
				missing_card_art_paths += 1
	_check(cards_with_art >= 61, "existing matching card art assets are wired")
	_check(missing_card_art_paths == 0, "configured card art paths load")
	_check(config.get_def("statuses", "anxiety").get("timing_hooks", []).has("round_start"), "anxiety declares round start hook")
	_check(config.get_def("statuses", "overtime").get("timing_hooks", []).has("round_start"), "overtime declares round start hook")
	_check(config.get_def("statuses", "weak").get("timing_hooks", []).has("deal_damage"), "weak declares damage hook")
	_check(config.get_def("statuses", "vulnerable").get("timing_hooks", []).has("damage_taken"), "vulnerable declares damage taken hook")
	_check(config.get_def("statuses", "style_layer").get("timing_hooks", []).has("deal_damage"), "style layer declares damage hook")
	_check(config.get_def("statuses", "api_gateway").get("timing_hooks", []).has("round_start"), "api gateway declares round start hook")
	var api_gateway_params: Dictionary = config.get_def("statuses", "api_gateway").get("params", {})
	_check(int(api_gateway_params.get("block_amount", 0)) > 0, "api gateway config has block amount")
	_check(int(api_gateway_params.get("service_threshold", 0)) == 2, "api gateway config has service threshold")
	_check(int(api_gateway_params.get("draw_amount", 0)) > 0, "api gateway config has draw amount")
	_check(config.get_def("statuses", "redis_warmup").get("timing_hooks", []).has("round_start"), "redis warmup declares round start hook")
	var redis_params: Dictionary = config.get_def("statuses", "redis_warmup").get("params", {})
	_check(int(redis_params.get("cost_reduction_amount", 0)) > 0, "redis warmup config has cost reduction amount")
	_check(config.get_def("statuses", "cost_reduction").get("timing_hooks", []).has("card_cost"), "cost reduction declares card cost hook")
	_check(config.get_def("statuses", "request_queue").get("timing_hooks", []).has("round_end"), "request queue declares round end hook")
	var request_params: Dictionary = config.get_def("statuses", "request_queue").get("params", {})
	_check(int(request_params.get("damage_per_request", 0)) > 0, "request queue config has damage per request")
	_check(config.get_def("statuses", "sharding").get("timing_hooks", []).has("add_cache"), "sharding declares cache gain hook")
	var sharding_status_params: Dictionary = config.get_def("statuses", "sharding").get("params", {})
	_check(int(sharding_status_params.get("extra_cache_amount", 0)) > 0, "sharding config has extra cache amount")
	_check(config.get_def("statuses", "state_boost").get("timing_hooks", []).has("card_played"), "state boost declares card played hook")
	var state_boost_params: Dictionary = config.get_def("statuses", "state_boost").get("params", {})
	_check(int(state_boost_params.get("trigger_play_count", 0)) == 4, "state boost config has fourth-card trigger")
	_check(int(state_boost_params.get("style_layer_amount", 0)) > 0, "state boost config grants style layer")
	_check(config.get_def("statuses", "vue_suite").get("timing_hooks", []).has("round_start"), "vue suite declares round start hook")
	var vue_params: Dictionary = config.get_def("statuses", "vue_suite").get("params", {})
	_check(int(vue_params.get("component_amount", 0)) > 0, "vue suite config has component amount")
	_check(config.get_def("statuses", "bug").get("timing_hooks", []).has("deal_damage"), "bug declares damage hook")
	_check(config.get_def("statuses", "diff").get("timing_hooks", []).has("inject_bug"), "diff declares bug injection hook")
	_check(config.get_def("statuses", "diff").get("timing_hooks", []).has("deal_damage"), "diff declares damage hook")
	_check(config.get_def("statuses", "auto_regression").get("timing_hooks", []).has("round_end"), "auto regression declares round end hook")
	var auto_regression_params: Dictionary = config.get_def("statuses", "auto_regression").get("params", {})
	_check(int(auto_regression_params.get("trigger_damage", 0)) > 0, "auto regression config has trigger damage")
	_check(int(auto_regression_params.get("case_amount", 0)) > 0, "auto regression config has case amount")
	_check(config.get_def("statuses", "case_matrix").get("timing_hooks", []).has("add_case"), "case matrix declares add case hook")
	var case_matrix_params: Dictionary = config.get_def("statuses", "case_matrix").get("params", {})
	_check(int(case_matrix_params.get("case_amount", 0)) > 0, "case matrix config has case amount")
	_check(config.get_def("statuses", "cache").get("timing_hooks", []).has("deal_damage"), "cache declares damage hook")
	_check(config.get_def("statuses", "compute").get("timing_hooks", []).has("deal_damage"), "compute declares damage hook")
	_check(config.get_def("statuses", "complexity").get("timing_hooks", []).has("add_compute"), "complexity declares compute gain hook")
	_check(config.get_def("statuses", "complexity").get("timing_hooks", []).has("round_start"), "complexity declares round start pressure hook")
	var complexity_params: Dictionary = config.get_def("statuses", "complexity").get("params", {})
	_check(int(complexity_params.get("compute_complexity_gain", 0)) > 0, "complexity config gains from compute")
	_check(int(complexity_params.get("pressure_threshold", 0)) > 0, "complexity config has pressure threshold")
	var complexity_burst_entries: Array = content.effect_entries(content.card_def("card_algo_complexity_burst").get("effect_group_id", ""))
	var complexity_burst_scales := false
	for entry in complexity_burst_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("complexity_multiplier", 0)) > 0:
			complexity_burst_scales = true
	_check(complexity_burst_scales, "algorithm complexity burst scales with complexity")
	var big_o_entries: Array = content.effect_entries(content.card_def("card_algo_big_o_compress").get("effect_group_id", ""))
	var big_o_compresses := false
	for entry in big_o_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "compress_complexity" and int(params.get("amount", 0)) > 0 and int(params.get("compute_per_complexity", 0)) > 0 and int(params.get("block_per_complexity", 0)) > 0:
			big_o_compresses = true
	_check(big_o_compresses, "algorithm big O compress converts complexity")
	var pruning_entries: Array = content.effect_entries(content.card_def("card_algo_pruning").get("effect_group_id", ""))
	var pruning_reduces_complexity := false
	var pruning_discounts_next_card := false
	for entry in pruning_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "modify_complexity" and int(params.get("amount", 0)) < 0:
			pruning_reduces_complexity = true
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "cost_reduction" and int(params.get("amount", 0)) > 0:
			pruning_discounts_next_card = true
	_check(pruning_reduces_complexity, "algorithm pruning lowers complexity")
	_check(pruning_discounts_next_card, "algorithm pruning discounts next card")
	_check(config.get_def("statuses", "requirement_change").get("timing_hooks", []).has("enemy_before_action"), "requirement change declares enemy action hook")
	var requirement_params: Dictionary = config.get_def("statuses", "requirement_change").get("params", {})
	_check(int(requirement_params.get("intent_amount_reduction", 0)) > 0, "requirement change config reduces intent amount")
	_check(int(requirement_params.get("consume_per_action", 0)) > 0, "requirement change config consumes stacks")
	_check(config.get_def("statuses", "scope_spread").get("timing_hooks", []).has("apply_status"), "scope spread declares status hook")
	var scope_params: Dictionary = config.get_def("statuses", "scope_spread").get("params", {})
	_check(int(scope_params.get("spread_amount", 0)) > 0, "scope spread config has spread amount")
	var scope_entries: Array = content.effect_entries(content.card_def("card_pm_scope_spread").get("effect_group_id", ""))
	var scope_spread_applies_status := false
	for entry in scope_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "scope_spread":
			scope_spread_applies_status = true
	_check(scope_spread_applies_status, "pm scope spread applies scope spread status")
	_check(config.get_def("statuses", "service_online").get("timing_hooks", []).has("round_end"), "service online declares round end hook")
	var flush_entries: Array = content.effect_entries(content.card_def("card_backend_flush_all").get("effect_group_id", ""))
	var flush_consumes_cache := false
	for entry in flush_entries:
		var params: Dictionary = entry.get("params", {})
		if bool(params.get("consume_cache", false)) and int(params.get("cache_multiplier", 0)) >= 3:
			flush_consumes_cache = true
	_check(flush_consumes_cache, "backend flush all consumes cache")
	var report_entries: Array = content.effect_entries(content.card_def("card_tester_report_lock").get("effect_group_id", ""))
	var report_lock_scales_status := false
	for entry in report_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("bug_multiplier", 0)) >= 2 and int(params.get("case_multiplier", 0)) >= 2 and int(params.get("diff_multiplier", 0)) >= 3:
			report_lock_scales_status = true
	_check(report_lock_scales_status, "tester report lock scales target statuses")
	_check(content.card_def("card_tester_92_bugs").get("target_type", "") == "selected", "tester fatal bug submission targets selected enemy")
	var fatal_bug_entries: Array = content.effect_entries(content.card_def("card_tester_92_bugs").get("effect_group_id", ""))
	var fatal_bug_has_hits := false
	for entry in fatal_bug_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "inject_bug" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0 and int(params.get("hits", 0)) >= 4:
			fatal_bug_has_hits = true
	_check(fatal_bug_has_hits, "tester fatal bug submission injects multiple bug hits")
	var auto_regression_entries: Array = content.effect_entries(content.card_def("card_tester_auto_regression").get("effect_group_id", ""))
	var auto_regression_applies_status := false
	for entry in auto_regression_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "auto_regression":
			auto_regression_applies_status = true
	_check(auto_regression_applies_status, "tester auto regression applies auto regression status")
	_check(content.card_def("card_tester_boundary_check").get("target_type", "") == "selected", "tester boundary check targets selected enemy")
	var boundary_check_entries: Array = content.effect_entries(content.card_def("card_tester_boundary_check").get("effect_group_id", ""))
	var boundary_check_has_params := false
	for entry in boundary_check_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "boundary_check" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0 and int(params.get("bonus_amount", 0)) > 0 and int(params.get("low_hp_percent", 0)) == 50 and int(params.get("high_attack_threshold", 0)) == 10:
			boundary_check_has_params = true
	_check(boundary_check_has_params, "tester boundary check has selected target thresholds")
	_check(content.card_def("card_tester_bug_upgrade").get("target_type", "") == "selected", "tester bug upgrade targets selected enemy")
	var bug_upgrade_entries: Array = content.effect_entries(content.card_def("card_tester_bug_upgrade").get("effect_group_id", ""))
	var bug_upgrade_upgrades_bug := false
	for entry in bug_upgrade_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "upgrade_bug" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0:
			bug_upgrade_upgrades_bug = true
	_check(bug_upgrade_upgrades_bug, "tester bug upgrade upgrades existing bug")
	_check(content.card_def("card_tester_regression_confirm").get("target_type", "") == "selected", "tester regression confirm targets selected enemy")
	var regression_confirm_entries: Array = content.effect_entries(content.card_def("card_tester_regression_confirm").get("effect_group_id", ""))
	var regression_confirm_checks_case := false
	for entry in regression_confirm_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "confirm_regression" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0 and int(params.get("draw_amount", 0)) > 0:
			regression_confirm_checks_case = true
	_check(regression_confirm_checks_case, "tester regression confirm checks cases before diff")
	var case_matrix_entries: Array = content.effect_entries(content.card_def("card_tester_case_matrix").get("effect_group_id", ""))
	var case_matrix_applies_status := false
	for entry in case_matrix_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "case_matrix":
			case_matrix_applies_status = true
	_check(case_matrix_applies_status, "tester case matrix applies case matrix status")
	_check(content.card_def("card_pm_schedule_compress").get("target_type", "") == "highest_priority_enemy", "pm schedule compress targets priority")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_salesman"), "pollute"), "salesman has pollute intent")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_workaholic_coworker"), "multi_attack"), "workaholic has multi attack intent")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_meeting_maniac"), "spawn"), "meeting maniac has spawn intent")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_compliance_judge"), "cleanse_player"), "compliance judge has cleanse intent")
	_check(content.phase_entries_for_enemy("boss_pitch_supervisor").size() >= 2, "pitch supervisor phase group resolves")
	_check(content.phase_entries_for_enemy("boss_mutant_ceo").size() >= 3, "ceo boss phase group resolves")
	_check(content.phase_entries_for_enemy("elite_outsource_manager").size() >= 1, "elite phase group resolves")

func _validate_class_resources(class_id: String) -> void:
	var battle = BattleServiceScript.new()
	var resources = battle.call("_initial_class_resources", class_id)
	_check(resources.size() > 0, "%s class resources initialized" % class_id)

func _validate_battle(class_id: String, config, content, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run(class_id)
	var first_node_id := String(run.get("map_state", {}).get("available_next_nodes", [])[0])
	var node: Dictionary = map.choose_node(run, first_node_id)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)
	var battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, node)
	var guard := 0
	while guard < 80 and not ["victory", "defeat"].has(battle.battle_state.get("phase", "")):
		var player: Dictionary = battle.battle_state.get("player", {})
		var played := false
		for i in range(player.get("hand", []).size()):
			if battle.can_play_card(i):
				battle.play_card(run, i, 0)
				played = true
				break
		if battle.battle_state.get("phase", "") == "victory":
			break
		if not played:
			battle.end_turn(run)
		guard += 1
	_check(battle.battle_state.get("phase", "") == "victory", "%s battle reaches victory" % class_id)
	_check(not run.get("pending_reward_state", {}).is_empty(), "%s reward generated" % class_id)
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	var reward: Dictionary = run.get("pending_reward_state", {})
	var chosen_card := String(reward.get("candidate_card_ids", [""])[0])
	var result: String = reward_service.accept_battle_reward(run, chosen_card)
	_check(result == "map", "%s reward returns to map" % class_id)
	_check(run.get("pending_reward_state", {}).is_empty(), "%s reward cleared" % class_id)
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "%s reward card added" % class_id)
	_check(int(run.get("currency_perf_points", 0)) > 0, "%s reward currency added" % class_id)

func _validate_combat_mechanics(config, content, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)

	var run := run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	var battle = _start_first_battle(run, content, map, executor)
	_check(int(battle.battle_state.get("player", {}).get("hand", []).size()) == 6, "blue light glasses opening draw")

	var player: Dictionary = battle.battle_state.get("player", {})
	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_lumbar_cushion")
	run["owned_relic_ids"].append("relic_hair_shampoo")
	var base_max_spirit := int(run.get("player_state", {}).get("max_spirit", 0))
	var base_current_spirit := int(run.get("player_state", {}).get("current_spirit", 0))
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	_check(int(player.get("max_spirit", 0)) == base_max_spirit + 6, "hair shampoo increases max spirit")
	_check(int(player.get("current_spirit", 0)) == base_current_spirit + 6, "hair shampoo increases current spirit")
	_check(int(player.get("current_block", 0)) >= 4, "lumbar cushion grants opening block")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_api_gateway"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("api_gateway", 0)) == 1, "backend api gateway status is applied")
	player["hand"] = []
	player["draw_pile"] = ["card_backend_interface_probe"]
	player["discard_pile"] = []
	player["class_resource_state"] = { "services": 0, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_block", 0)) == 4, "backend api gateway grants block on round start")
	_check(not player.get("hand", []).has("card_backend_interface_probe"), "backend api gateway needs services to draw")
	player["hand"] = []
	player["draw_pile"] = ["card_backend_interface_probe"]
	player["discard_pile"] = []
	player["class_resource_state"] = { "services": 2, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(player.get("hand", []).has("card_backend_interface_probe"), "backend api gateway draws with enough services")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_coffee_boost", "card_shared_coffee_boost", "card_shared_coffee_boost"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 0
	for _i in range(3):
		battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) >= 1, "frontend design link grants style layer on third card")

	run = run_session.create_new_run("frontend")
	run["owned_relic_ids"].append("relic_figma_library")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	executor.execute([{ "effect_type": "add_component", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var components_after_first := int(player.get("class_resource_state", {}).get("components", 0))
	executor.execute([{ "effect_type": "add_component", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(components_after_first == 2, "figma library duplicates first component")
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 3, "figma library triggers only once")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_component_reuse"]
	player["draw_pile"] = ["card_frontend_pixel_tap"]
	player["current_energy"] = 3
	player["class_resource_state"]["components"] = 2
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 3, "frontend component reuse copies existing component")
	_check(player.get("hand", []).has("card_frontend_pixel_tap"), "frontend component reuse draws after copy")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_component_reuse"]
	player["draw_pile"] = ["card_frontend_pixel_tap"]
	player["current_energy"] = 3
	player["class_resource_state"]["components"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 0, "frontend component reuse needs an existing component")
	_check(not player.get("hand", []).has("card_frontend_pixel_tap"), "frontend component reuse does not draw without copy")

	run = run_session.create_new_run("frontend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var state_boost_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	state_boost_enemy["current_hp"] = 50
	state_boost_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_pixel_tap"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["cards_played_this_turn"] = 3
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = { "state_boost": 1 }
	battle.play_card(run, 0, 0)
	_check(int(state_boost_enemy.get("current_hp", 0)) == 39, "frontend state boost buffs the fourth card")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend state boost style layer is consumed by attack")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_vue_suite"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["class_resource_state"]["components"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("vue_suite", 0)) == 1, "frontend vue suite status is applied")
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 1, "frontend vue suite creates a component on round start")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var motion_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	motion_enemy["current_hp"] = 50
	motion_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_motion_overload"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["cards_played_this_turn"] = 3
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(motion_enemy.get("current_hp", 0)) == 32, "frontend motion overload uses current turn play count")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var crash_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	crash_enemy["current_hp"] = 60
	crash_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_crash_animation"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["class_resource_state"]["style_layers"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(crash_enemy.get("current_hp", 0)) == 35, "frontend crash animation converts style layers into extra hits")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend crash animation consumes all style layers")

	run = run_session.create_new_run("product_manager")
	run["owned_relic_ids"] = ["relic_gantt_roadmap"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = []
	player["draw_pile"] = ["card_pm_schedule_compress", "card_pm_priority_shuffle"]
	var gantt_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	gantt_enemy["intent"] = { "intent_type": "attack", "amount": 9 }
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var gantt_hand_after_first := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(gantt_hand_after_first == 1, "gantt roadmap draws on first intent change")
	_check(int(player.get("hand", []).size()) == 1, "gantt roadmap triggers only once")

	run = run_session.create_new_run("product_manager")
	run["owned_relic_ids"] = ["relic_pm_meeting_room_claim"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var claim_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	claim_enemy["status_list"] = {}
	player["class_resource_state"]["requirement_change_marks"] = 0
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(claim_enemy.get("status_list", {}).get("requirement_change", 0)) == 2, "meeting room claim strengthens first requirement change")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) == 2, "meeting room claim syncs boosted requirement resource")
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(claim_enemy.get("status_list", {}).get("requirement_change", 0)) == 3, "meeting room claim triggers only once per turn")
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["hand"] = []
	battle.call("_start_player_turn", run, false)
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(claim_enemy.get("status_list", {}).get("requirement_change", 0)) == 5, "meeting room claim resets on next turn")

	run = run_session.create_new_run("algorithm")
	run["owned_relic_ids"] = ["relic_paper_citation"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["class_resource_state"]["complexity"] = 3
	var paper_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	paper_enemy["current_block"] = 0
	paper_enemy["current_hp"] = 50
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(paper_enemy.get("current_hp", 0)) == 42, "paper citation adds damage at high complexity")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 0
	executor.execute([{ "effect_type": "add_compute", "target_type": "self", "params": { "amount": 2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 2, "algorithm compute gain adds compute")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 2, "algorithm compute gain raises complexity")

	run = run_session.create_new_run("algorithm")
	run["owned_relic_ids"].append("relic_gpu_training_card")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	executor.execute([{ "effect_type": "add_compute", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var compute_after_gpu := int(player.get("class_resource_state", {}).get("compute", 0))
	var complexity_after_gpu := int(player.get("class_resource_state", {}).get("complexity", 0))
	executor.execute([{ "effect_type": "add_compute", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(compute_after_gpu == 2, "gpu training card adds compute on first gain")
	_check(complexity_after_gpu == 2, "gpu training card bonus compute also raises complexity")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 3, "gpu training card triggers only once")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 3, "subsequent compute raises complexity once")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_publish_script"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("services", 0)) >= 1, "backend publish script deploys service")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var circuit_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	circuit_enemy["intent"] = { "intent_type": "attack", "amount": 12 }
	player["hand"] = ["card_backend_circuit_breaker"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["services"] = 2
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) == 17, "backend circuit breaker gains service and pressure block")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "backend circuit breaker gains cache from services")
	_check(int(player.get("class_resource_state", {}).get("services", 0)) == 2, "backend circuit breaker keeps services online")
	_check(int(player.get("current_energy", 0)) == 2, "backend circuit breaker charges card cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_redis_warmup"]
	player["current_energy"] = 3
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 3, "backend redis warmup grants large cache")
	_check(int(player.get("status_list", {}).get("redis_warmup", 0)) == 1, "backend redis warmup status is pending")
	player["hand"] = ["card_backend_api_gateway"]
	player["current_energy"] = 1
	_check(not battle.can_play_card(0), "backend redis warmup does not discount same turn")
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("status_list", {}).get("redis_warmup", 0)) == 0, "backend redis warmup clears at next round start")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 1, "backend redis warmup enables next card discount")
	_check(battle.hand_card_cost(0) == 1, "backend redis warmup previews discounted cost")
	_check(battle.can_play_card(0), "backend redis warmup lets discounted card play")
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 0, "backend redis warmup charges discounted cost")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 0, "backend redis warmup discount is consumed")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	for mq_enemy in battle.battle_state.get("enemies", []):
		mq_enemy["current_hp"] = 50
		mq_enemy["current_block"] = 0
	player["hand"] = ["card_backend_message_queue"]
	player["current_energy"] = 3
	player["class_resource_state"]["requests"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("requests", 0)) == 3, "backend message queue stores request resource")
	_check(int(player.get("status_list", {}).get("request_queue", 0)) == 3, "backend message queue stores request status")
	battle.call("_round_end_triggers", run)
	var request_damage_ok := true
	for mq_enemy in battle.battle_state.get("enemies", []):
		if int(mq_enemy.get("current_hp", 0)) != 41:
			request_damage_ok = false
	_check(request_damage_ok, "backend message queue damages all enemies at round end")
	_check(int(player.get("class_resource_state", {}).get("requests", 0)) == 0, "backend message queue consumes request resource")
	_check(int(player.get("status_list", {}).get("request_queue", 0)) == 0, "backend message queue consumes request status")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_sharding"]
	player["current_energy"] = 3
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("sharding", 0)) == 1, "backend sharding status is applied")
	executor.execute([{ "effect_type": "add_cache", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "backend sharding adds extra first cache each turn")
	executor.execute([{ "effect_type": "add_cache", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 3, "backend sharding only triggers once per turn")
	player["hand"] = []
	player["draw_pile"] = []
	player["discard_pile"] = []
	battle.call("_start_player_turn", run, false)
	executor.execute([{ "effect_type": "add_cache", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 5, "backend sharding resets on next turn")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_traffic_shaping"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["damage_taken_this_turn"] = 6
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) >= 6, "backend traffic shaping grants block")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 3, "backend traffic shaping converts pressure to cache")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var degrade_enemy_a: Dictionary = battle.battle_state.get("enemies", [])[0]
	degrade_enemy_a["intent"] = { "intent_type": "attack", "amount": 10 }
	var degrade_enemy_b := {
		"enemy_def_id": "enemy_workaholic_coworker",
		"name": "多段压测同事",
		"max_hp": 30,
		"current_hp": 30,
		"current_block": 0,
		"phase_index": 0,
		"intent": { "intent_type": "multi_attack", "amount": 5, "hits": 3 },
		"status_list": {},
		"runtime_flags": {},
	}
	battle.battle_state["enemies"].append(degrade_enemy_b)
	player["hand"] = ["card_backend_service_degrade"]
	player["current_energy"] = 1
	player["current_block"] = 0
	player["class_resource_state"]["services"] = 2
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(degrade_enemy_a.get("intent", {}).get("amount", 0)) == 6, "backend service degrade lowers attack intent")
	_check(int(degrade_enemy_b.get("intent", {}).get("amount", 0)) == 1, "backend service degrade lowers multi attack intent")
	_check(int(player.get("current_block", 0)) == 8, "backend service degrade gains block per existing service")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 1, "backend service degrade preserves services into cache")
	_check(int(player.get("class_resource_state", {}).get("services", 0)) == 2, "backend service degrade does not consume services")
	_check(int(player.get("current_energy", 0)) == 1, "backend service degrade remains zero cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_trace_chain"]
	player["draw_pile"] = ["card_backend_api_gateway", "card_backend_interface_probe"]
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(player.get("hand", []).has("card_backend_api_gateway"), "backend trace chain fetches service card from draw pile")
	_check(player.get("draw_pile", []).has("card_backend_interface_probe"), "backend trace chain leaves non-service draw card")
	_check(not player.get("draw_pile", []).has("card_backend_api_gateway"), "backend trace chain removes fetched service from draw pile")
	_check(int(player.get("current_energy", 0)) == 2, "backend trace chain charges card cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_trace_chain"]
	player["draw_pile"] = ["card_backend_interface_probe"]
	player["discard_pile"] = ["card_backend_sharding"]
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(not player.get("hand", []).has("card_backend_sharding"), "backend trace chain does not search discard pile")
	_check(player.get("draw_pile", []).has("card_backend_interface_probe"), "backend trace chain leaves draw pile when no service card exists")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var flush_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	flush_enemy["current_hp"] = 80
	flush_enemy["current_block"] = 0
	flush_enemy["status_list"] = {}
	player["hand"] = ["card_backend_flush_all"]
	player["current_energy"] = 3
	player["class_resource_state"]["cache"] = 4
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(flush_enemy.get("current_hp", 0)) == 54, "backend flush all spends cache for damage")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 0, "backend flush all consumes stored cache")

	run = run_session.create_new_run("frontend")
	run["owned_relic_ids"].append("relic_standing_desk")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["current_block"] = 0
	executor.execute([{ "effect_type": "gain_block", "target_type": "self", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	executor.execute([{ "effect_type": "gain_block", "target_type": "self", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) == 12, "standing desk adds only first block per turn")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = []
	player["draw_pile"] = []
	player["discard_pile"] = ["card_shared_keyboard_smash", "card_shared_standup", "card_shared_meeting_mute"]
	executor.execute([{ "effect_type": "move_card", "target_type": "self", "params": { "source": "discard", "destination": "draw", "amount": 1, "card_id": "card_shared_standup" } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(not player.get("discard_pile", []).has("card_shared_standup"), "move card removes named card from source pile")
	_check(player.get("draw_pile", []).has("card_shared_standup"), "move card adds named card to destination pile")
	executor.execute([{ "effect_type": "move_card", "target_type": "self", "params": { "source": "draw", "destination": "hand", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(player.get("hand", []).has("card_shared_standup"), "move card moves top card when no card id is specified")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	var deck_before_executor_reward := int(run.get("deck_state", {}).get("master_deck", []).size())
	executor.execute([{ "effect_type": "add_random_card", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before_executor_reward + 1, "executor add random card updates run deck")
	var relic_before_executor_reward := int(run.get("owned_relic_ids", []).size())
	executor.execute([{ "effect_type": "add_random_relic", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before_executor_reward + 1, "executor add random relic updates run relics")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "executor add random relic avoids duplicates")
	executor.execute([{ "effect_type": "upgrade_card", "target_type": "self", "params": { "amount": 1, "card_id": "card_backend_interface_probe" } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(run.get("deck_state", {}).get("upgraded_cards", []).has("card_backend_interface_probe"), "executor upgrade card updates run deck")
	_check(battle.battle_state.get("upgraded_card_ids", []).has("card_backend_interface_probe"), "executor upgrade card updates active battle")
	var circuit_count_before := _count_card(run.get("deck_state", {}).get("master_deck", []), "card_backend_circuit_breaker")
	executor.execute([{ "effect_type": "remove_card", "target_type": "self", "params": { "amount": 1, "card_id": "card_backend_circuit_breaker" } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(_count_card(run.get("deck_state", {}).get("master_deck", []), "card_backend_circuit_breaker") == circuit_count_before - 1, "executor remove card updates run deck")
	_check(run.get("deck_state", {}).get("removed_cards", []).has("card_backend_circuit_breaker"), "executor remove card records removed card")

	run = run_session.create_new_run("tester")
	battle = _start_first_battle(run, content, map, executor)
	var enemies: Array = battle.battle_state.get("enemies", [])
	if enemies.size() == 1:
		enemies.append(enemies[0].duplicate(true))
		enemies[1]["name"] = "测试副目标"
		enemies[1]["current_hp"] = 20
	battle.battle_state["enemies"] = enemies
	executor.execute([{ "effect_type": "deal_damage", "target_type": "all_enemies", "params": { "amount": 3 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(battle.battle_state["enemies"][0].get("current_hp", 0)) < int(battle.battle_state["enemies"][0].get("max_hp", 0)), "all enemies damages first target")
	_check(int(battle.battle_state["enemies"][1].get("current_hp", 0)) == 17, "all enemies damages second target")
	battle.select_target(1)
	_check(battle.selected_target_index() == 1, "battle target selection records index")
	var second_before := int(battle.battle_state["enemies"][1].get("current_hp", 0))
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_tester_defect_log"]
	player["current_energy"] = 3
	battle.play_card(run, 0, battle.selected_target_index())
	_check(int(battle.battle_state["enemies"][1].get("current_hp", 0)) < second_before, "selected target receives card damage")
	executor.execute([{ "effect_type": "inject_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var status: Dictionary = battle.battle_state["enemies"][0].get("status_list", {})
	_check(int(status.get("bug", 0)) >= 1, "tester injects bug")
	_check(int(status.get("case_mark", 0)) >= 1, "tester starter relic adds case")
	var tester_resources: Dictionary = player.get("class_resource_state", {})
	_check(int(tester_resources.get("bugs", 0)) >= 1, "tester bug status syncs resource")
	_check(int(tester_resources.get("cases", 0)) >= 1, "tester case status syncs resource")
	status["diff"] = 2
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "attack", "amount": 8 }
	player["class_resource_state"]["diff_tags"] = 2
	var bug_before := int(status.get("bug", 0))
	executor.execute([{ "effect_type": "inject_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	status = battle.battle_state["enemies"][0].get("status_list", {})
	tester_resources = player.get("class_resource_state", {})
	_check(int(status.get("bug", 0)) == bug_before + 2, "diff adds extra bug during reproduction")
	_check(int(status.get("diff", 0)) == 1, "diff is consumed by bug reproduction")
	_check(int(tester_resources.get("diff_tags", 0)) == 1, "diff resource decrements after reproduction")
	_check(int(battle.battle_state["enemies"][0].get("intent", {}).get("amount", 0)) == 4, "diff-boosted bug weakens intent by final bug amount")

	run = run_session.create_new_run("tester")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var fatal_bug_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	fatal_bug_enemy["status_list"] = { "diff": 2 }
	fatal_bug_enemy["intent"] = { "intent_type": "attack", "amount": 14 }
	player["class_resource_state"]["bugs"] = 0
	player["class_resource_state"]["diff_tags"] = 2
	player["hand"] = ["card_tester_92_bugs"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(fatal_bug_enemy.get("status_list", {}).get("bug", 0)) == 6, "tester fatal bug submission injects multiple bug stacks")
	_check(int(fatal_bug_enemy.get("status_list", {}).get("diff", 0)) == 0, "tester fatal bug submission consumes diff across hits")
	_check(int(player.get("class_resource_state", {}).get("bugs", 0)) == 6, "tester fatal bug submission syncs bug resource")
	_check(int(player.get("class_resource_state", {}).get("diff_tags", 0)) == 0, "tester fatal bug submission syncs consumed diff")
	_check(int(fatal_bug_enemy.get("intent", {}).get("amount", 0)) == 2, "tester fatal bug submission weakens intent per injected bug")

	run = run_session.create_new_run("tester")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var boundary_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	boundary_enemy["max_hp"] = 40
	boundary_enemy["current_hp"] = 18
	boundary_enemy["current_block"] = 0
	boundary_enemy["status_list"] = {}
	boundary_enemy["intent"] = { "intent_type": "attack", "amount": 4 }
	player["class_resource_state"]["cases"] = 0
	player["hand"] = ["card_tester_boundary_check"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(boundary_enemy.get("status_list", {}).get("case_mark", 0)) == 2, "tester boundary check adds bonus case to low hp target")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 2, "tester boundary check syncs low hp bonus cases")
	boundary_enemy["current_hp"] = 40
	boundary_enemy["status_list"] = {}
	boundary_enemy["intent"] = { "intent_type": "attack", "amount": 4 }
	player["class_resource_state"]["cases"] = 0
	executor.execute([{ "effect_type": "boundary_check", "target_type": "selected", "params": { "amount": 1, "bonus_amount": 1, "low_hp_percent": 50, "high_attack_threshold": 10 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(boundary_enemy.get("status_list", {}).get("case_mark", 0)) == 1, "tester boundary check adds base case without boundary")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 1, "tester boundary check syncs base cases")
	boundary_enemy["status_list"] = {}
	boundary_enemy["intent"] = { "intent_type": "multi_attack", "amount": 4, "hits": 3 }
	player["class_resource_state"]["cases"] = 0
	executor.execute([{ "effect_type": "boundary_check", "target_type": "selected", "params": { "amount": 1, "bonus_amount": 1, "low_hp_percent": 50, "high_attack_threshold": 10 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(boundary_enemy.get("status_list", {}).get("case_mark", 0)) == 2, "tester boundary check adds bonus case to high attack target")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 2, "tester boundary check syncs high attack bonus cases")

	run = run_session.create_new_run("tester")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var report_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	report_enemy["current_hp"] = 80
	report_enemy["current_block"] = 0
	report_enemy["status_list"] = { "bug": 3, "case_mark": 2, "diff": 1 }
	player["hand"] = ["card_tester_report_lock"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(report_enemy.get("current_hp", 0)) == 57, "tester report lock scales bug case and diff damage")

	run = run_session.create_new_run("tester")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var regression_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	regression_enemy["current_hp"] = 40
	regression_enemy["current_block"] = 0
	regression_enemy["status_list"] = { "bug": 2 }
	player["hand"] = ["card_tester_auto_regression"]
	player["current_energy"] = 3
	player["class_resource_state"]["cases"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("auto_regression", 0)) == 1, "tester auto regression status is applied")
	battle.call("_round_end_triggers", run)
	_check(int(regression_enemy.get("current_hp", 0)) == 36, "tester auto regression triggers bug damage at round end")
	_check(int(regression_enemy.get("status_list", {}).get("case_mark", 0)) == 1, "tester auto regression adds case to bugged target")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 1, "tester auto regression syncs case resource")

	run = run_session.create_new_run("tester")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var upgrade_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	upgrade_enemy["status_list"] = { "bug": 1 }
	upgrade_enemy["intent"] = { "intent_type": "attack", "amount": 8 }
	player["class_resource_state"]["bugs"] = 1
	player["hand"] = ["card_tester_bug_upgrade"]
	player["current_energy"] = 3
	player["current_block"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) >= 6, "tester bug upgrade grants block")
	_check(int(upgrade_enemy.get("status_list", {}).get("bug", 0)) == 2, "tester bug upgrade adds bug to existing bug")
	_check(int(player.get("class_resource_state", {}).get("bugs", 0)) == 2, "tester bug upgrade syncs bug resource")
	_check(int(upgrade_enemy.get("intent", {}).get("amount", 0)) == 6, "tester bug upgrade weakens intent by upgraded bug")
	upgrade_enemy["status_list"] = {}
	player["class_resource_state"]["bugs"] = 0
	executor.execute([{ "effect_type": "upgrade_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(upgrade_enemy.get("status_list", {}).get("bug", 0)) == 0, "tester bug upgrade needs an existing bug")

	run = run_session.create_new_run("tester")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var confirm_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	confirm_enemy["status_list"] = { "case_mark": 2 }
	player["class_resource_state"]["diff_tags"] = 0
	player["hand"] = ["card_tester_regression_confirm"]
	player["draw_pile"] = ["card_tester_smoke_test"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(confirm_enemy.get("status_list", {}).get("diff", 0)) == 1, "tester regression confirm adds diff to cased target")
	_check(int(player.get("class_resource_state", {}).get("diff_tags", 0)) == 1, "tester regression confirm syncs diff resource")
	_check(player.get("hand", []).has("card_tester_smoke_test"), "tester regression confirm draws on cased target")
	confirm_enemy["status_list"] = {}
	var confirm_hand_size := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "confirm_regression", "target_type": "selected", "params": { "amount": 1, "draw_amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(confirm_enemy.get("status_list", {}).get("diff", 0)) == 0, "tester regression confirm needs an existing case")
	_check(int(player.get("hand", []).size()) == confirm_hand_size, "tester regression confirm does not draw without case")

	run = run_session.create_new_run("tester")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var matrix_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	matrix_enemy["status_list"] = {}
	player["hand"] = ["card_tester_case_matrix"]
	player["current_energy"] = 3
	player["class_resource_state"]["cases"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("case_matrix", 0)) == 1, "tester case matrix status is applied")
	executor.execute([{ "effect_type": "add_case", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(matrix_enemy.get("status_list", {}).get("case_mark", 0)) == 2, "tester case matrix doubles first case each turn")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 2, "tester case matrix syncs bonus case resource")
	executor.execute([{ "effect_type": "add_case", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(matrix_enemy.get("status_list", {}).get("case_mark", 0)) == 3, "tester case matrix triggers only once per turn")
	battle.call("_start_player_turn", run, false)
	executor.execute([{ "effect_type": "add_case", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(matrix_enemy.get("status_list", {}).get("case_mark", 0)) == 5, "tester case matrix resets on next turn")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var style_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	style_enemy["current_hp"] = 50
	style_enemy["current_block"] = 0
	style_enemy["status_list"] = {}
	player["class_resource_state"]["style_layers"] = 2
	player["status_list"] = {}
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(style_enemy.get("current_hp", 0)) == 43, "style layer resource boosts damage")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 1, "style layer resource is consumed after damage")
	style_enemy["current_hp"] = 50
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = { "style_layer": 3 }
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(style_enemy.get("current_hp", 0)) == 42, "style layer status boosts damage")
	_check(int(player.get("status_list", {}).get("style_layer", 0)) == 2, "style layer status is consumed after damage")

	run = run_session.create_new_run("product_manager")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["draw_pile"] = ["card_pm_change_wording"]
	var hand_before := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) >= 4, "pm starter relic grants block")
	_check(int(player.get("hand", []).size()) == hand_before + 1, "pm starter relic draws")
	var pm_resources: Dictionary = player.get("class_resource_state", {})
	_check(int(pm_resources.get("requirement_change_marks", 0)) >= 1, "pm requirement change syncs resource")
	executor.execute([{ "effect_type": "apply_status", "target_type": "self", "params": { "status_id": "priority", "amount": 2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	pm_resources = player.get("class_resource_state", {})
	_check(int(pm_resources.get("priority_targets", 0)) >= 2, "pm priority status syncs resource")
	_check(not battle.card_needs_target("card_pm_schedule_compress"), "pm priority attack auto resolves target")
	var pm_enemies: Array = battle.battle_state.get("enemies", [])
	if pm_enemies.size() == 1:
		pm_enemies.append(pm_enemies[0].duplicate(true))
		pm_enemies[1]["name"] = "高优先级目标"
	pm_enemies[0]["current_hp"] = 50
	pm_enemies[0]["current_block"] = 0
	pm_enemies[0]["status_list"] = {}
	pm_enemies[1]["current_hp"] = 50
	pm_enemies[1]["current_block"] = 0
	pm_enemies[1]["status_list"] = { "priority": 3 }
	battle.battle_state["enemies"] = pm_enemies
	player["hand"] = ["card_pm_schedule_compress"]
	player["current_energy"] = 3
	battle.select_target(0)
	battle.play_card(run, 0, 0)
	_check(int(battle.battle_state["enemies"][0].get("current_hp", 0)) == 50, "pm priority attack ignores selected low priority target")
	_check(int(battle.battle_state["enemies"][1].get("current_hp", 0)) < 50, "pm priority attack hits highest priority target")
	_check(int(battle.battle_state["enemies"][1].get("status_list", {}).get("requirement_change", 0)) >= 1, "pm priority attack marks hit target")

	run = run_session.create_new_run("product_manager")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var changed_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	changed_enemy["current_hp"] = 50
	changed_enemy["current_block"] = 0
	changed_enemy["intent"] = { "intent_type": "attack", "amount": 10 }
	changed_enemy["status_list"] = { "requirement_change": 2 }
	battle.battle_state["enemies"] = [changed_enemy]
	player["current_spirit"] = 50
	player["current_block"] = 0
	player["status_list"] = {}
	player["class_resource_state"]["requirement_change_marks"] = 2
	battle.call("_enemy_turn", run)
	_check(int(player.get("current_spirit", 0)) == 44, "requirement change reduces next attack before enemy action")
	_check(int(changed_enemy.get("status_list", {}).get("requirement_change", 0)) == 1, "requirement change consumes one stack before action")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) == 1, "requirement change resource syncs after consumption")

	run = run_session.create_new_run("product_manager")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var spread_enemies: Array = battle.battle_state.get("enemies", [])
	if spread_enemies.size() == 1:
		spread_enemies.append(spread_enemies[0].duplicate(true))
		spread_enemies[1]["name"] = "被蔓延目标"
	spread_enemies[0]["status_list"] = {}
	spread_enemies[1]["status_list"] = {}
	battle.battle_state["enemies"] = spread_enemies
	player["status_list"] = { "scope_spread": 1 }
	player["class_resource_state"]["requirement_change_marks"] = 0
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(spread_enemies[0].get("status_list", {}).get("requirement_change", 0)) == 1, "scope spread keeps original requirement target")
	_check(int(spread_enemies[1].get("status_list", {}).get("requirement_change", 0)) == 1, "scope spread adds requirement change to another enemy")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) >= 2, "scope spread syncs spread requirement resource")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var optimum_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	optimum_enemy["current_hp"] = 80
	optimum_enemy["current_block"] = 0
	player["hand"] = ["card_algo_global_optimum"]
	player["current_energy"] = 3
	player["class_resource_state"]["compute"] = 4
	battle.play_card(run, 0, 0)
	_check(int(optimum_enemy.get("current_hp", 0)) == 46, "algorithm x finisher spends energy and compute for damage")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm x finisher consumes stored compute")
	_check(int(player.get("current_energy", 0)) == 1, "algorithm starter relic refunds first x card")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var burst_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	burst_enemy["current_hp"] = 60
	burst_enemy["current_block"] = 0
	player["hand"] = ["card_algo_complexity_burst"]
	player["current_energy"] = 3
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 5
	battle.play_card(run, 0, 0)
	_check(int(burst_enemy.get("current_hp", 0)) == 32, "algorithm complexity burst scales damage from complexity")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 5, "algorithm complexity burst keeps complexity")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm complexity burst does not add generic compute")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var pruning_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	pruning_enemy["current_hp"] = 60
	pruning_enemy["current_block"] = 0
	player["hand"] = ["card_algo_pruning", "card_algo_complexity_burst"]
	player["current_energy"] = 2
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 1, "algorithm pruning reduces complexity")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 1, "algorithm pruning grants next-card discount")
	_check(battle.hand_card_cost(0) == 1, "algorithm pruning previews discounted next card")
	_check(battle.can_play_card(0), "algorithm pruning enables discounted next card")
	battle.play_card(run, 0, 0)
	_check(int(pruning_enemy.get("current_hp", 0)) == 48, "algorithm pruning discount lets next card resolve")
	_check(int(player.get("current_energy", 0)) == 0, "algorithm pruning discount charges reduced cost")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 0, "algorithm pruning discount is consumed")

	run = run_session.create_new_run("algorithm")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_big_o_compress"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 4
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 1, "algorithm big O compress spends stored complexity")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 3, "algorithm big O compress converts complexity to compute")
	_check(int(player.get("current_block", 0)) == 6, "algorithm big O compress converts complexity to block")
	_check(int(player.get("current_energy", 0)) == 2, "algorithm big O compress charges card cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_cold_brew_bucket")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_hotfix_rollback"]
	player["current_energy"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 1, "cold brew refunds first zero cost card")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_rollback"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = { "weak": 2, "vulnerable": 1, "anxiety": 1, "overtime": 1 }
	battle.play_card(run, 0, 0)
	var rollback_status: Dictionary = player.get("status_list", {})
	_check(int(player.get("current_block", 0)) >= 6, "shared rollback grants block")
	_check(not rollback_status.has("weak"), "shared rollback clears weak")
	_check(not rollback_status.has("vulnerable"), "shared rollback clears vulnerable")
	_check(not rollback_status.has("anxiety"), "shared rollback clears anxiety")
	_check(rollback_status.has("overtime"), "shared rollback keeps heavier overtime")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_standup"]
	player["draw_pile"] = ["card_shared_badge_throw"]
	player["discard_pile"] = []
	player["current_energy"] = 1
	player["current_block"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 1, "shared standup refunds its energy")
	_check(player.get("hand", []).has("card_shared_badge_throw"), "shared standup draws a replacement")
	_check(int(player.get("current_block", 0)) >= 5, "shared standup grants block")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_meeting_mute"]
	player["current_energy"] = 3
	var mute_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	mute_enemy["intent"] = { "intent_type": "attack", "amount": 9 }
	_check(battle.card_needs_target("card_shared_meeting_mute"), "shared meeting mute requests a target")
	battle.play_card(run, 0, 0)
	_check(int(mute_enemy.get("intent", {}).get("amount", 0)) == 5, "shared meeting mute reduces attack intent")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_read_replica")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["current_block"] = 0
	var cache_before := int(player.get("class_resource_state", {}).get("cache", 0))
	battle.call("_enemy_attack", player, battle.battle_state.get("enemies", [])[0], 6, run)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) > cache_before, "read replica returns cache on damage")

	run = run_session.create_new_run("tester")
	run["owned_relic_ids"].append("relic_error_log_repo")
	battle = _start_first_battle(run, content, map, executor)
	var error_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	var error_hp_before := int(error_enemy.get("current_hp", 0))
	executor.execute([{ "effect_type": "inject_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(error_enemy.get("current_hp", 0)) < error_hp_before, "error log repo damages on bug")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var status_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	status_enemy["current_block"] = 0
	status_enemy["current_hp"] = 50
	player["status_list"] = { "weak": 1 }
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 8 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(status_enemy.get("current_hp", 0)) == 44, "player weak reduces outgoing damage")
	status_enemy["current_hp"] = 50
	status_enemy["status_list"] = { "vulnerable": 1 }
	player["status_list"] = {}
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 8 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(status_enemy.get("current_hp", 0)) == 38, "enemy vulnerable increases outgoing damage")
	status_enemy["status_list"] = { "weak": 1 }
	player["status_list"] = { "vulnerable": 1 }
	player["current_spirit"] = 40
	player["current_block"] = 0
	battle.call("_enemy_attack", player, status_enemy, 8, run)
	_check(int(player.get("current_spirit", 0)) == 31, "enemy weak and player vulnerable modify incoming damage")
	battle.call("_round_end_triggers", run)
	_check(int(player.get("status_list", {}).get("vulnerable", 0)) == 0, "player short debuff decays at turn end")
	player["status_list"] = { "anxiety": 2 }
	player["current_energy"] = 3
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_energy", 0)) == 2, "anxiety reduces round start energy")
	_check(int(player.get("status_list", {}).get("anxiety", 0)) == 1, "anxiety decays after triggering")
	player["status_list"] = { "overtime": 2 }
	player["current_spirit"] = 40
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_spirit", 0)) == 38, "overtime damages at round start")
	_check(int(player.get("status_list", {}).get("overtime", 0)) == 1, "overtime decays after triggering")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["status_list"] = {}
	player["class_resource_state"] = { "compute": 0, "complexity": 3 }
	player["current_energy"] = 3
	player["current_spirit"] = 40
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_energy", 0)) == 2, "high complexity reduces round start energy")
	_check(int(player.get("current_spirit", 0)) == 40, "complexity pressure uses configured spirit loss")
	player["status_list"] = { "complexity": 4 }
	player["class_resource_state"] = { "compute": 0, "complexity": 1 }
	player["current_energy"] = 3
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_energy", 0)) == 2, "complexity status and resource do not double count")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["status_list"] = { "service_online": 2 }
	player["class_resource_state"] = { "services": 0, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "service online status adds cache at round start")
	_check(int(player.get("current_block", 0)) == 4, "service online status adds block at round start")
	player["class_resource_state"] = { "services": 2, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "service online status and resource do not double count")
	player["status_list"] = { "service_online": 1, "sharding": 1 }
	player["class_resource_state"] = { "services": 0, "cache": 0 }
	player["relic_runtime_flags"] = {}
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "sharding boosts service online cache gain")
	player["status_list"] = {}
	player["class_resource_state"] = { "services": 2, "cache": 2 }
	var service_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	service_enemy["current_hp"] = 30
	service_enemy["current_block"] = 0
	battle.call("_round_end_triggers", run)
	_check(int(service_enemy.get("current_hp", 0)) == 26, "service online damages enemies at round end")

	run = run_session.create_new_run("backend")
	run["deck_state"]["upgraded_cards"] = ["card_backend_interface_probe"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_interface_probe"]
	player["current_energy"] = 3
	var target: Dictionary = battle.battle_state.get("enemies", [])[0]
	var hp_before := int(target.get("current_hp", 0))
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 3, "upgraded one-cost card costs zero")
	_check(hp_before - int(target.get("current_hp", 0)) >= 12, "upgraded card effect is stronger")

func _validate_enemy_intent_actions(config, content, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)

	var run := run_session.create_new_run("backend")
	var battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	var player: Dictionary = battle.battle_state.get("player", {})
	player["discard_pile"] = []
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "pollute", "card_id": "card_status_option_promise", "amount": 2, "destination": "discard" }
	battle.call("_enemy_turn", run)
	_check(_count_card(player.get("discard_pile", []), "card_status_option_promise") == 2, "enemy pollute adds status cards")

	run = run_session.create_new_run("frontend")
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	player = battle.battle_state.get("player", {})
	player["current_spirit"] = 40
	player["current_block"] = 2
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "multi_attack", "amount": 3, "hits": 3 }
	battle.call("_enemy_turn", run)
	_check(int(player.get("current_spirit", 0)) == 33, "enemy multi attack consumes block across hits")

	run = run_session.create_new_run("tester")
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	var enemies_before := int(battle.battle_state.get("enemies", []).size())
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "spawn", "enemy_id": "enemy_process_specialist", "amount": 1, "max_allies": 3 }
	battle.call("_enemy_turn", run)
	_check(int(battle.battle_state.get("enemies", []).size()) == enemies_before + 1, "enemy spawn adds combatant")
	_check(String(battle.battle_state["enemies"][1].get("enemy_def_id", "")) == "enemy_process_specialist", "spawned enemy uses requested def")
	_check(not battle.battle_state["enemies"][1].get("intent", {}).is_empty(), "spawned enemy receives an intent")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	player = battle.battle_state.get("player", {})
	player["discard_pile"] = []
	player["status_list"] = { "service_online": 1, "style_layer": 2, "anxiety": 1 }
	player["class_resource_state"] = { "compute": 3, "complexity": 2 }
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "cleanse_player", "amount": 2, "card_id": "card_status_meeting_minutes" }
	battle.call("_enemy_turn", run)
	_check(not player.get("status_list", {}).has("service_online"), "enemy cleanse removes player positive status")
	_check(player.get("status_list", {}).has("anxiety"), "enemy cleanse keeps player debuff")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 1, "enemy cleanse reduces player resources")
	_check(_count_card(player.get("discard_pile", []), "card_status_meeting_minutes") == 1, "enemy cleanse can add pollution")

	run = run_session.create_new_run("product_manager")
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	var enemy: Dictionary = battle.battle_state["enemies"][0]
	enemy["current_block"] = 0
	enemy["status_list"] = { "weak": 1, "vulnerable": 1 }
	enemy["intent"] = { "intent_type": "phase_shift", "amount": 5 }
	battle.call("_enemy_turn", run)
	_check(int(enemy.get("phase_index", 0)) == 1, "enemy phase shift increments phase")
	_check(int(enemy.get("current_block", 0)) == 5, "enemy phase shift grants block")
	_check(int(enemy.get("status_list", {}).get("weak", 0)) == 0, "enemy short status decays after action")

func _validate_enemy_phase_scripts(config, content, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)

	var run := run_session.create_new_run("backend")
	run["current_floor"] = 6
	var boss_node := { "id": "test_boss_ch1", "node_type": "boss", "floor": 6 }
	var battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, boss_node)
	var boss: Dictionary = battle.battle_state.get("enemies", [])[0]
	var player: Dictionary = battle.battle_state.get("player", {})
	player["hand"] = []
	boss["current_hp"] = 70
	boss["current_block"] = 0
	battle.call("_check_enemy_phase_triggers", run)
	_check(int(boss.get("phase_index", 0)) == 1, "boss phase threshold advances phase")
	_check(_count_card(player.get("hand", []), "card_status_option_promise") == 1, "boss phase pollutes hand")
	_check(int(boss.get("current_block", 0)) >= 10, "boss phase grants block")
	battle.call("_check_enemy_phase_triggers", run)
	_check(_count_card(player.get("hand", []), "card_status_option_promise") == 1, "boss phase triggers only once")
	boss["current_hp"] = 35
	battle.call("_check_enemy_phase_triggers", run)
	_check(_count_card(player.get("draw_pile", []), "card_curse_next_year_promotion") == 1, "boss second phase pollutes draw pile")
	_check(String(boss.get("intent", {}).get("intent_type", "")) == "attack", "boss second phase forces intent")
	_check(int(boss.get("intent", {}).get("amount", 0)) == 18, "boss forced intent keeps configured amount")

	run = run_session.create_new_run("algorithm")
	run["current_chapter"] = 3
	run["current_floor"] = 18
	var ceo_node := { "id": "test_boss_ch3", "node_type": "boss", "floor": 18 }
	battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, ceo_node)
	var ceo: Dictionary = battle.battle_state.get("enemies", [])[0]
	var enemies_before := int(battle.battle_state.get("enemies", []).size())
	ceo["current_hp"] = 120
	battle.call("_check_enemy_phase_triggers", run)
	_check(int(battle.battle_state.get("enemies", []).size()) == enemies_before + 1, "ceo phase summons meeting enemy")
	_check(int(ceo.get("current_block", 0)) >= 12, "ceo phase grants block")

	run = run_session.create_new_run("tester")
	battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	var elite: Dictionary = battle.call("_build_enemy", "elite_outsource_manager")
	battle.battle_state = {
		"player": {
			"current_spirit": 72,
			"current_block": 0,
			"status_list": {},
			"class_resource_state": {},
			"discard_pile": [],
			"draw_pile": [],
			"hand": [],
		},
		"enemies": [elite],
		"phase": "player",
		"log": [],
	}
	elite["current_hp"] = 40
	var elite_count_before := int(battle.battle_state.get("enemies", []).size())
	battle.call("_check_enemy_phase_triggers", run)
	_check(int(battle.battle_state.get("enemies", []).size()) == elite_count_before + 1, "elite phase can summon support")
	_check(int(elite.get("current_block", 0)) >= 8, "elite phase grants block")

func _validate_map_constraints(run: Dictionary, label: String) -> void:
	var floors: Array = run.get("map_state", {}).get("floors", [])
	var has_shop := false
	var has_rest := false
	var boss_count := 0
	for layer in floors:
		for node in layer:
			has_shop = has_shop or node.get("node_type", "") == "shop"
			has_rest = has_rest or node.get("node_type", "") == "rest"
			boss_count += 1 if node.get("node_type", "") == "boss" else 0
	_check(has_shop, "%s includes shop" % label)
	_check(has_rest, "%s includes rest" % label)
	_check(boss_count == 1, "%s has one boss" % label)

func _validate_shop_event_rest(config, content, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("frontend")
	reward_service.prepare_shop_stock(run)
	_check(run.get("shop_state", {}).get("card_stock", []).size() > 0, "shop has card stock")
	_check(run.get("shop_state", {}).get("relic_stock", []).size() > 0, "shop has relic stock")
	run["currency_perf_points"] = 500
	var card_id := String(run["shop_state"]["card_stock"][0])
	var relic_id := String(run["shop_state"]["relic_stock"][0])
	var deck_before := int(run["deck_state"]["master_deck"].size())
	var relic_before := int(run["owned_relic_ids"].size())
	_check(reward_service.buy_shop_card(run, card_id), "shop card purchase succeeds")
	_check(int(run["deck_state"]["master_deck"].size()) == deck_before + 1, "shop card added")
	_check(reward_service.buy_shop_relic(run, relic_id), "shop relic purchase succeeds")
	_check(int(run["owned_relic_ids"].size()) == relic_before + 1, "shop relic added")
	_check(reward_service.remove_shop_card(run), "shop remove succeeds")
	_check(int(run["deck_state"]["removed_cards"].size()) == 1, "shop remove records card")

	run = run_session.create_new_run("backend")
	run["currency_perf_points"] = 200
	reward_service.prepare_shop_stock(run)
	var target_card_id := String(run["deck_state"]["master_deck"][0])
	var target_count_before := _count_card(run["deck_state"]["master_deck"], target_card_id)
	var currency_before_remove := int(run.get("currency_perf_points", 0))
	var targeted_remove_cost: int = reward_service.remove_cost(run)
	_check(reward_service.remove_shop_card(run, target_card_id), "shop targeted remove succeeds")
	_check(_count_card(run["deck_state"]["master_deck"], target_card_id) == target_count_before - 1, "shop targeted remove removes selected card")
	_check(run["deck_state"]["removed_cards"].has(target_card_id), "shop targeted remove records selected card")
	_check(int(run.get("currency_perf_points", 0)) == currency_before_remove - targeted_remove_cost, "shop targeted remove charges cost")
	_check(not reward_service.remove_shop_card(run, target_card_id), "shop second remove is blocked")

	run = run_session.create_new_run("backend")
	run["currency_perf_points"] = 200
	reward_service.prepare_shop_stock(run)
	currency_before_remove = int(run.get("currency_perf_points", 0))
	_check(not reward_service.remove_shop_card(run, "card_missing_for_test"), "shop missing card remove fails")
	_check(int(run.get("currency_perf_points", 0)) == currency_before_remove, "shop missing card remove does not charge")
	_check(not bool(run.get("shop_state", {}).get("removed", false)), "shop missing card remove keeps remove available")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	run["currency_perf_points"] = 100
	reward_service.prepare_shop_stock(run)
	_check(not run.get("shop_state", {}).get("relic_stock", []).has("relic_blue_light_glasses"), "shop stock excludes owned relics")
	var refresh_cost: int = reward_service.shop_refresh_cost(run)
	var currency_before_refresh := int(run.get("currency_perf_points", 0))
	_check(reward_service.refresh_shop_stock(run), "shop refresh succeeds")
	_check(int(run.get("currency_perf_points", 0)) == currency_before_refresh - refresh_cost, "shop refresh charges configured cost")
	_check(int(run.get("shop_state", {}).get("refresh_count", 0)) == 1, "shop refresh increments counter")
	_check(run.get("shop_state", {}).get("card_stock", []).size() > 0, "shop refresh keeps card stock")
	_check(not run.get("shop_state", {}).get("relic_stock", []).has("relic_blue_light_glasses"), "shop refresh keeps owned relics out")

	run = run_session.create_new_run("frontend")
	run["owned_relic_ids"].append("relic_employee_coupon")
	run["currency_perf_points"] = 200
	reward_service.prepare_shop_stock(run)
	var discounted_card_cost: int = reward_service.card_cost(run)
	_check(reward_service.refresh_shop_stock(run), "shop refresh with discount relic succeeds")
	_check(reward_service.card_cost(run) == discounted_card_cost, "shop refresh does not consume first purchase discount")
	_check(reward_service.remove_shop_card(run), "shop remove after refresh succeeds")
	_check(bool(run.get("shop_state", {}).get("removed", false)), "shop remove flag set before refresh")
	_check(reward_service.refresh_shop_stock(run), "shop refresh after remove succeeds")
	_check(bool(run.get("shop_state", {}).get("removed", false)), "shop refresh preserves remove flag")

	run = run_session.create_new_run("tester")
	reward_service.prepare_event(run)
	_check(not reward_service.current_event(run).is_empty(), "event prepared")
	var history_before := int(run.get("event_history_ids", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("event_history_ids", []).size()) == history_before + 1, "event history recorded")
	_check(run.get("event_state", {}).is_empty(), "event state cleared")
	_validate_event_effect_resolution(config, content, map, meta, reward_service)

	run = run_session.create_new_run("algorithm")
	var ps: Dictionary = run.get("player_state", {})
	ps["current_spirit"] = 10
	run["player_state"] = ps
	var rest_id := _first_node_of_type(run, "rest")
	run["current_node_id"] = rest_id
	reward_service.rest_recover(run)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) > 10, "rest recover increases spirit")
	run = run_session.create_new_run("algorithm")
	rest_id = _first_node_of_type(run, "rest")
	run["current_node_id"] = rest_id
	reward_service.rest_upgrade(run)
	_check(int(run.get("deck_state", {}).get("upgraded_cards", []).size()) == 1, "rest upgrade records card")
	run = run_session.create_new_run("backend")
	rest_id = _first_node_of_type(run, "rest")
	run["current_node_id"] = rest_id
	reward_service.rest_upgrade_card(run, "card_backend_publish_script")
	_check(run.get("deck_state", {}).get("upgraded_cards", []).has("card_backend_publish_script"), "rest selected upgrade records chosen card")

func _validate_event_effect_resolution(config, content, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)

	var run := run_session.create_new_run("backend")
	run["event_state"] = { "event_id": "event_unlocked_office" }
	var currency_before := int(run.get("currency_perf_points", 0))
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("currency_perf_points", 0)) == currency_before + 45, "event gain currency applies")

	run = run_session.create_new_run("backend")
	run["deck_state"]["upgraded_cards"] = ["card_backend_interface_probe"]
	run["event_state"] = { "event_id": "event_unlocked_office" }
	reward_service.choose_event_option(run, 1)
	_check(int(run.get("deck_state", {}).get("upgraded_cards", []).size()) == 2, "event upgrade skips already upgraded card")
	_check(run.get("deck_state", {}).get("upgraded_cards", []).has("card_backend_circuit_breaker"), "event upgrade records next eligible card")

	run = run_session.create_new_run("frontend")
	run["event_state"] = { "event_id": "event_wrong_email" }
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "event draw card adds run card outside battle")

	run = run_session.create_new_run("tester")
	var ps: Dictionary = run.get("player_state", {})
	ps["current_spirit"] = 20
	run["player_state"] = ps
	run["event_state"] = { "event_id": "event_pantry_gossip" }
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == 32, "event recover spirit applies")

	run = run_session.create_new_run("tester")
	run["event_state"] = { "event_id": "event_pantry_gossip" }
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 1)
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before - 1, "event remove card shrinks deck")
	_check(int(run.get("deck_state", {}).get("removed_cards", []).size()) == 1, "event remove card records removal")

	run = run_session.create_new_run("algorithm")
	run["currency_perf_points"] = 10
	run["event_state"] = { "event_id": "event_vending_bug" }
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("currency_perf_points", 0)) == 0, "event negative currency clamps at zero")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "event add random card applies")

	run = run_session.create_new_run("product_manager")
	ps = run.get("player_state", {})
	ps["current_spirit"] = 30
	run["player_state"] = ps
	run["event_state"] = { "event_id": "event_intern_blame" }
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == 22, "event lose spirit applies")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "event combined add card applies")

	run = run_session.create_new_run("frontend")
	run["event_state"] = { "event_id": "event_private_talk" }
	var relic_before := int(run.get("owned_relic_ids", []).size())
	reward_service.choose_event_option(run, 1)
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before + 1, "event add random relic applies")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "event relic reward avoids duplicates")

func _validate_reward_economy(config, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_parking_pass")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": [],
		"currency_amount": 10,
		"source_node_type": "elite_battle",
	}
	reward_service.accept_battle_reward(run, "")
	_check(int(run.get("currency_perf_points", 0)) == 25, "parking pass adds elite currency")
	_check(int(run.get("run_counters", {}).get("elite_wins", 0)) == 1, "elite reward increments counter")

	run = run_session.create_new_run("backend")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_blue_light_glasses", "relic_lumbar_cushion"],
		"currency_amount": 11,
		"source_node_type": "elite_battle",
	}
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	var relic_before := int(run.get("owned_relic_ids", []).size())
	reward_service.accept_battle_reward(run, "card_backend_interface_probe", "relic_blue_light_glasses")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "reward selected card added")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before + 1, "reward selected relic added")
	_check(run.get("owned_relic_ids", []).has("relic_blue_light_glasses"), "reward chosen relic id added")
	_check(run.get("pending_reward_state", {}).is_empty(), "reward selection clears pending reward")

	run = run_session.create_new_run("backend")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_blue_light_glasses"],
		"currency_amount": 7,
		"source_node_type": "elite_battle",
	}
	relic_before = int(run.get("owned_relic_ids", []).size())
	reward_service.accept_battle_reward(run, "", "")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before, "reward can skip relic")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_blue_light_glasses"],
		"currency_amount": 7,
		"source_node_type": "elite_battle",
	}
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.accept_battle_reward(run, "card_frontend_pixel_tap", "relic_blue_light_glasses")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before, "reward ignores non-candidate card")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "reward ignores duplicate relic")

	run = run_session.create_new_run("frontend")
	run["owned_relic_ids"].append("relic_employee_coupon")
	run["currency_perf_points"] = 100
	reward_service.prepare_shop_stock(run)
	var before_currency := int(run.get("currency_perf_points", 0))
	var card_id := String(run["shop_state"]["card_stock"][0])
	var cost: int = int(reward_service.card_cost(run))
	_check(cost < RewardService.CARD_COST, "employee coupon discounts first shop purchase")
	reward_service.buy_shop_card(run, card_id)
	_check(int(run.get("currency_perf_points", 0)) == before_currency - cost, "discounted card cost charged")
	_check(reward_service.card_cost(run) == RewardService.CARD_COST, "shop discount consumed")

func _validate_save_roundtrip(config, map, meta, save) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("product_manager")
	run["current_scene_tag"] = "map"
	save.save_suspend(run, meta.meta_state)
	_check(save.has_suspend(), "suspend save exists")
	_check(not save.load_suspend().get("serialized_meta_state_snapshot", {}).is_empty(), "suspend stores meta snapshot")
	var restored_session = RunSessionScript.new()
	restored_session.call("setup", config, map, meta)
	_check(restored_session.restore_from_suspend(save.load_suspend()), "suspend restore succeeds")
	_check(restored_session.run_state.get("selected_class_id", "") == "product_manager", "suspend selected class roundtrip")
	save.clear_suspend()

	run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var content = ContentResolverScript.new()
	content.call("setup", config)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)
	run = run_session.create_new_run("backend")
	var battle = _start_first_battle(run, content, map, executor)
	run["current_scene_tag"] = "battle"
	battle.battle_state["player"]["current_energy"] = 1
	battle.battle_state["log"].append("battle_roundtrip_marker")
	save.save_suspend(run, meta.meta_state)
	var battle_save: Dictionary = save.load_suspend()
	_check(String(battle_save.get("scene_tag", "")) == "battle", "battle suspend scene tag stored")
	var restored_battle_session = RunSessionScript.new()
	restored_battle_session.call("setup", config, map, meta)
	_check(restored_battle_session.restore_from_suspend(battle_save), "battle suspend run restore succeeds")
	var restored_battle = BattleServiceScript.new()
	restored_battle.call("setup", content, executor)
	_check(restored_battle.restore_battle(restored_battle_session.run_state), "battle suspend restores battle service")
	_check(int(restored_battle.battle_state.get("player", {}).get("current_energy", 0)) == 1, "battle suspend restores player energy")
	_check(restored_battle.battle_state.get("log", []).has("battle_roundtrip_marker"), "battle suspend restores battle log")
	save.clear_suspend()

func _validate_meta_settlement(config, map, meta) -> void:
	meta.meta_state = meta.default_meta_state()
	var backend_class: Dictionary = config.get_def("classes", "backend")
	var tester_class: Dictionary = config.get_def("classes", "tester")
	var hr_class: Dictionary = config.get_def("classes", "hr")
	_check(meta.is_class_playable("backend"), "meta marks backend playable")
	_check(meta.is_class_playable("product_manager"), "meta marks first playable office class playable")
	_check(not meta.is_class_playable("hr"), "meta keeps hr out of playable classes")
	_check(meta.class_availability_label(backend_class) == "可出战", "career tree labels playable class")
	_check(meta.class_availability_label(hr_class) == "未开放", "career tree labels locked hr placeholder")
	_check(meta.class_unlock_label(hr_class).contains("扩展预留"), "career tree explains hr placeholder")
	_check(meta.class_unlock_progress(tester_class) == "0/3", "career tree reports elite unlock progress")
	meta.meta_state["career_milestones"] = { "elite_wins": 2, "events_resolved": 4, "highest_floor_reached": 12 }
	_check(meta.class_unlock_progress(tester_class) == "2/3", "career tree updates milestone progress")

	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("tester")
	run["current_floor"] = 8
	run["run_counters"]["elite_wins"] = 2
	run["run_counters"]["events_resolved"] = 3
	run["defeated_boss_ids"] = ["boss_pitch_supervisor"]
	var currency_before := int(meta.meta_state.get("owned_discomfort_currency", 0))
	var earned: int = meta.settle_run(run, false)
	_check(earned > 0, "meta settlement earns currency")
	_check(int(meta.meta_state.get("owned_discomfort_currency", 0)) == currency_before + earned, "meta currency increases")
	_check(int(meta.meta_state.get("career_milestones", {}).get("elite_wins", 0)) >= 2, "meta records elite wins")
	_check(meta.meta_state.get("defeated_boss_records", []).has("boss_pitch_supervisor"), "meta records defeated boss")
	_check(int(run.get("settlement_state", {}).get("earned_currency", 0)) == earned, "settlement summary stores earned currency")
	_check(int(run.get("settlement_state", {}).get("highest_floor", 0)) == 8, "settlement summary stores floor")
	_check(int(run.get("settlement_state", {}).get("elite_count", 0)) == 2, "settlement summary stores elites")
	var currency_after := int(meta.meta_state.get("owned_discomfort_currency", 0))
	var earned_again: int = meta.settle_run(run, false)
	_check(earned_again == earned, "settlement returns stable earned amount after settled")
	_check(int(meta.meta_state.get("owned_discomfort_currency", 0)) == currency_after, "settlement is idempotent for currency")

	run = run_session.create_new_run("backend")
	run["current_floor"] = 18
	run["run_flags"]["victory"] = true
	run["defeated_boss_ids"] = ["boss_pitch_supervisor", "boss_mutant_hr", "boss_mutant_ceo"]
	var victory_earned: int = meta.settle_run(run, true)
	_check(victory_earned >= 80, "victory settlement includes victory bonus")
	_check(bool(run.get("settlement_state", {}).get("victory", false)), "settlement summary stores victory")
	_check(int(run.get("settlement_state", {}).get("boss_count", 0)) == 3, "settlement summary stores boss count")

func _validate_meta_upgrades(config, map, meta, reward_service) -> void:
	meta.meta_state = meta.default_meta_state()
	meta.meta_state["owned_discomfort_currency"] = 100
	var chair_cost := int(config.get_def("meta_upgrades", "meta_chair").get("cost_curve", [0])[0])
	_check(meta.buy_upgrade("meta_chair"), "meta upgrade purchase succeeds")
	_check(meta.get_upgrade_level("meta_chair") == 1, "meta upgrade level increases")
	_check(int(meta.meta_state.get("owned_discomfort_currency", 0)) == 100 - chair_cost, "meta upgrade purchase charges currency")
	_check(not meta.buy_upgrade("unlock_hr"), "career unlock cannot be bought as workstation upgrade")

	meta.meta_state = meta.default_meta_state()
	meta.meta_state["meta_upgrade_levels"] = {
		"meta_chair": 2,
		"meta_privacy_screen": 3,
		"meta_coffee_beans": 2,
		"meta_hard_drive": 2,
	}
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	var ps: Dictionary = run.get("player_state", {})
	_check(int(ps.get("max_spirit", 0)) == 80, "meta chair raises run max spirit")
	_check(int(ps.get("current_spirit", 0)) == 80, "meta chair raises run current spirit")
	_check(int(ps.get("base_energy", 0)) == 4, "meta coffee beans raises base energy at max level")
	_check(int(ps.get("opening_block_bonus", 0)) == 6, "meta privacy screen grants opening block bonus")
	_check(int(ps.get("opening_draw_bonus", 0)) == 2, "meta hard drive grants opening draw bonus")

	meta.meta_state = meta.default_meta_state()
	meta.meta_state["meta_upgrade_levels"] = { "meta_nap_bed": 3 }
	run = run_session.create_new_run("algorithm")
	ps = run.get("player_state", {})
	ps["max_spirit"] = 100
	ps["current_spirit"] = 40
	run["player_state"] = ps
	run["current_node_id"] = _first_node_of_type(run, "rest")
	reward_service.rest_recover(run)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == 82, "meta nap bed increases rest recovery")

	meta.meta_state = meta.default_meta_state()
	meta.meta_state["meta_upgrade_levels"] = { "meta_canteen_card": 2 }
	run = run_session.create_new_run("frontend")
	run["currency_perf_points"] = 100
	reward_service.prepare_shop_stock(run)
	var card_id := String(run.get("shop_state", {}).get("card_stock", [])[0])
	var discounted_cost: int = reward_service.card_cost(run)
	_check(discounted_cost == RewardService.CARD_COST - 10, "meta canteen card discounts first shop purchase")
	reward_service.buy_shop_card(run, card_id)
	_check(int(run.get("currency_perf_points", 0)) == 100 - discounted_cost, "meta canteen card discounted purchase charges correctly")
	_check(reward_service.card_cost(run) == RewardService.CARD_COST, "meta canteen card discount is consumed")
	meta.meta_state = meta.default_meta_state()

func _validate_boss_progression(config, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	run["current_node_id"] = String(run.get("map_state", {}).get("boss_node_id", ""))
	var result: String = map.complete_current_node(run)
	_check(result == "next_chapter", "chapter 1 boss advances chapter")
	_check(int(run.get("current_chapter", 0)) == 2, "chapter index is 2 after boss")
	map.generate_chapter(run, 3)
	run["current_node_id"] = String(run.get("map_state", {}).get("boss_node_id", ""))
	result = map.complete_current_node(run)
	_check(result == "run_victory", "chapter 3 boss yields run victory")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK: %s" % label)
	else:
		push_error("FAIL: %s" % label)
		failed = true

func _first_node_of_type(run: Dictionary, node_type: String) -> String:
	for layer in run.get("map_state", {}).get("floors", []):
		for node in layer:
			if node.get("node_type", "") == node_type:
				return String(node.get("id", ""))
	return ""

func _start_first_battle(run: Dictionary, content, map, executor):
	var first_node_id := String(run.get("map_state", {}).get("available_next_nodes", [])[0])
	var node: Dictionary = map.choose_node(run, first_node_id)
	var battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, node)
	return battle

func _isolate_first_enemy(battle) -> void:
	var enemies: Array = battle.battle_state.get("enemies", [])
	if enemies.is_empty():
		return
	battle.battle_state["enemies"] = [enemies[0]]

func _count_card(pile: Array, card_id: String) -> int:
	var count := 0
	for item in pile:
		if String(item) == card_id:
			count += 1
	return count

func _has_intent_type(entries: Array, intent_type: String) -> bool:
	for entry in entries:
		if String(entry.get("intent_type", "")) == intent_type:
			return true
	return false

func _array_has_no_duplicates(values: Array) -> bool:
	var seen := {}
	for value in values:
		var key := String(value)
		if seen.has(key):
			return false
		seen[key] = true
	return true
