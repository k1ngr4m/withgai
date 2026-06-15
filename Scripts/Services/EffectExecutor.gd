class_name EffectExecutor
extends RefCounted

var config_service: ConfigService

func setup(p_config_service: ConfigService) -> void:
	config_service = p_config_service

func execute(entries: Array, battle_state: Dictionary, run_state: Dictionary, target_index: int, log: Array) -> void:
	for entry in entries:
		_execute_entry(entry, battle_state, run_state, target_index, log)

func _execute_entry(entry: Dictionary, battle_state: Dictionary, run_state: Dictionary, target_index: int, log: Array) -> void:
	var effect_type := String(entry.get("effect_type", ""))
	var params: Dictionary = entry.get("params", {})
	var amount := int(params.get("amount", 0))
	match effect_type:
		"gain_block":
			_player(battle_state)["current_block"] = int(_player(battle_state).get("current_block", 0)) + amount
			log.append("获得 %d 防线" % amount)
		"deal_damage":
			_damage_enemy(battle_state, target_index, amount, log)
		"draw_cards":
			_draw_cards(battle_state, amount, log)
		"gain_energy":
			_player(battle_state)["current_energy"] = int(_player(battle_state).get("current_energy", 0)) + amount
		"apply_status":
			_apply_status(entry.get("target_type", "selected"), battle_state, target_index, String(params.get("status_id", "")), int(params.get("amount", 1)), log)
		"remove_status":
			_remove_status(entry.get("target_type", "selected"), battle_state, target_index, String(params.get("status_id", "")))
		"gain_currency":
			run_state["currency_perf_points"] = max(0, int(run_state.get("currency_perf_points", 0)) + amount)
		"recover_spirit":
			var ps: Dictionary = run_state.get("player_state", {})
			ps["current_spirit"] = min(int(ps.get("max_spirit", 72)), int(ps.get("current_spirit", 72)) + amount)
			run_state["player_state"] = ps
		"lose_spirit":
			var ps2: Dictionary = run_state.get("player_state", {})
			ps2["current_spirit"] = max(1, int(ps2.get("current_spirit", 72)) - amount)
			run_state["player_state"] = ps2
		"deploy_service":
			_add_class_resource(battle_state, "services", max(1, amount), log, "部署服务")
		"add_cache":
			_add_class_resource(battle_state, "cache", amount, log, "缓存")
		"add_component":
			_add_class_resource(battle_state, "components", amount, log, "组件")
		"add_style_layer":
			_add_class_resource(battle_state, "style_layers", amount, log, "样式层")
		"inject_bug":
			_enemy_status(battle_state, target_index, "bug", max(1, amount), log)
			_modify_intent(battle_state, target_index, -2 * max(1, amount), log)
		"add_case":
			_enemy_status(battle_state, target_index, "case_mark", max(1, amount), log)
		"add_diff":
			_enemy_status(battle_state, target_index, "diff", max(1, amount), log)
		"add_compute":
			_add_class_resource(battle_state, "compute", amount, log, "算力")
		"modify_complexity":
			_add_class_resource(battle_state, "complexity", amount, log, "复杂度")
		"modify_intent":
			_modify_intent(battle_state, target_index, amount, log)
		"upgrade_card", "remove_card", "add_random_card", "add_random_relic", "create_card", "move_card", "add_relic", "spawn_enemy":
			log.append("事件效果已记录：%s" % effect_type)
		_:
			log.append("未实现效果：%s" % effect_type)

func _player(battle_state: Dictionary) -> Dictionary:
	return battle_state.get("player", {})

func _alive_enemies(battle_state: Dictionary) -> Array:
	return battle_state.get("enemies", []).filter(func(enemy): return int(enemy.get("current_hp", 0)) > 0)

func _target_enemy(battle_state: Dictionary, target_index: int) -> Dictionary:
	var enemies: Array = battle_state.get("enemies", [])
	if enemies.is_empty():
		return {}
	target_index = clamp(target_index, 0, enemies.size() - 1)
	if int(enemies[target_index].get("current_hp", 0)) <= 0:
		for enemy in enemies:
			if int(enemy.get("current_hp", 0)) > 0:
				return enemy
	return enemies[target_index]

func _damage_enemy(battle_state: Dictionary, target_index: int, amount: int, log: Array) -> void:
	var enemy := _target_enemy(battle_state, target_index)
	if enemy.is_empty():
		return
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	var bonus := int(resources.get("style_layers", 0)) + int(enemy.get("status_list", {}).get("case_mark", 0))
	var damage := int(max(0, amount + bonus))
	var block := int(enemy.get("current_block", 0))
	var blocked := int(min(block, damage))
	enemy["current_block"] = block - blocked
	enemy["current_hp"] = max(0, int(enemy.get("current_hp", 0)) - (damage - blocked))
	log.append("对 %s 造成 %d 伤害" % [enemy.get("name", "敌人"), damage])

func _draw_cards(battle_state: Dictionary, amount: int, log: Array) -> void:
	var player := _player(battle_state)
	for i in range(amount):
		if player.get("draw_pile", []).is_empty():
			var discard: Array = player.get("discard_pile", [])
			if discard.is_empty():
				break
			discard.shuffle()
			player["draw_pile"] = discard
			player["discard_pile"] = []
		if player.get("draw_pile", []).is_empty():
			break
		player["hand"].append(player["draw_pile"].pop_back())
	if amount > 0:
		log.append("抽 %d 张牌" % amount)

func _apply_status(target_type: String, battle_state: Dictionary, target_index: int, status_id: String, amount: int, log: Array) -> void:
	if status_id.is_empty():
		return
	if target_type == "self":
		var player := _player(battle_state)
		var statuses: Dictionary = player.get("status_list", {})
		statuses[status_id] = int(statuses.get(status_id, 0)) + amount
		player["status_list"] = statuses
		if status_id == "service_online":
			_add_class_resource(battle_state, "services", amount, log, "服务")
		elif status_id == "style_layer":
			_add_class_resource(battle_state, "style_layers", amount, log, "样式层")
		elif status_id == "compute":
			_add_class_resource(battle_state, "compute", amount, log, "算力")
	else:
		_enemy_status(battle_state, target_index, status_id, amount, log)

func _remove_status(target_type: String, battle_state: Dictionary, target_index: int, status_id: String) -> void:
	if target_type == "self":
		_player(battle_state).get("status_list", {}).erase(status_id)
	else:
		_target_enemy(battle_state, target_index).get("status_list", {}).erase(status_id)

func _enemy_status(battle_state: Dictionary, target_index: int, status_id: String, amount: int, log: Array) -> void:
	var enemy := _target_enemy(battle_state, target_index)
	if enemy.is_empty():
		return
	var statuses: Dictionary = enemy.get("status_list", {})
	statuses[status_id] = int(statuses.get(status_id, 0)) + amount
	enemy["status_list"] = statuses
	log.append("%s 获得 %s x%d" % [enemy.get("name", "敌人"), status_id, amount])

func _add_class_resource(battle_state: Dictionary, key: String, amount: int, log: Array, label: String) -> void:
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	resources[key] = max(0, int(resources.get(key, 0)) + amount)
	player["class_resource_state"] = resources
	if amount != 0:
		log.append("%s %+d" % [label, amount])

func _modify_intent(battle_state: Dictionary, target_index: int, amount: int, log: Array) -> void:
	var enemy := _target_enemy(battle_state, target_index)
	if enemy.is_empty():
		return
	var intent: Dictionary = enemy.get("intent", {})
	if intent.get("intent_type", "") == "attack":
		intent["amount"] = max(0, int(intent.get("amount", 0)) + amount)
		enemy["intent"] = intent
		log.append("%s 攻击意图 %+d" % [enemy.get("name", "敌人"), amount])
