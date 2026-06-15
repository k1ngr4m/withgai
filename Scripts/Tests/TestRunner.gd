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
	_validate_shop_event_rest(config, content, map, meta, reward_service)
	_validate_reward_economy(config, map, meta, reward_service)
	_validate_save_roundtrip(config, map, meta, save)
	_validate_meta_settlement(config, map, meta)
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
	for enemy in config.all_defs("enemies"):
		if content.intent_entries_for_enemy(enemy.get("id", "")).is_empty():
			enemies_missing_intents += 1
		if content.reward_profile(enemy.get("reward_profile_id", "")).is_empty():
			enemies_missing_rewards += 1
	_check(enemies_missing_intents == 0, "enemy intent groups resolve")
	_check(enemies_missing_rewards == 0, "enemy reward profiles resolve")
	var encounter_missing_enemies := 0
	for encounter in config.all_defs("encounters"):
		for enemy_id in encounter.get("enemy_ids", []):
			if content.enemy_def(enemy_id).is_empty():
				encounter_missing_enemies += 1
	_check(encounter_missing_enemies == 0, "encounter enemies resolve")

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
	player["hand"] = ["card_backend_publish_script"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("services", 0)) >= 1, "backend publish script deploys service")

	run = run_session.create_new_run("frontend")
	run["owned_relic_ids"].append("relic_standing_desk")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["current_block"] = 0
	executor.execute([{ "effect_type": "gain_block", "target_type": "self", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	executor.execute([{ "effect_type": "gain_block", "target_type": "self", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) == 12, "standing desk adds only first block per turn")

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

	run = run_session.create_new_run("product_manager")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["draw_pile"] = ["card_pm_change_wording"]
	var hand_before := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) >= 4, "pm starter relic grants block")
	_check(int(player.get("hand", []).size()) == hand_before + 1, "pm starter relic draws")

	run = run_session.create_new_run("algorithm")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_global_optimum"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 1, "algorithm starter relic refunds first x card")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_read_replica")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["current_block"] = 0
	var cache_before := int(player.get("class_resource_state", {}).get("cache", 0))
	battle.call("_enemy_attack", player, battle.battle_state.get("enemies", [])[0], 6, run)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) > cache_before, "read replica returns cache on damage")

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

func _validate_shop_event_rest(config, _content, map, meta, reward_service) -> void:
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

	run = run_session.create_new_run("tester")
	reward_service.prepare_event(run)
	_check(not reward_service.current_event(run).is_empty(), "event prepared")
	var history_before := int(run.get("event_history_ids", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("event_history_ids", []).size()) == history_before + 1, "event history recorded")
	_check(run.get("event_state", {}).is_empty(), "event state cleared")

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

func _validate_meta_settlement(config, map, meta) -> void:
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
