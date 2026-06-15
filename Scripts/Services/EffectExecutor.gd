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
			_gain_block(battle_state, run_state, amount, log)
		"deal_damage":
			_damage_enemies(entry.get("target_type", "selected"), battle_state, run_state, target_index, amount, log)
		"draw_cards":
			_draw_cards(battle_state, amount, log)
		"gain_energy":
			_player(battle_state)["current_energy"] = int(_player(battle_state).get("current_energy", 0)) + amount
		"apply_status":
			_apply_status(entry.get("target_type", "selected"), battle_state, run_state, target_index, String(params.get("status_id", "")), int(params.get("amount", 1)), log)
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
			_apply_component_relics(battle_state, run_state, log)
		"add_style_layer":
			_add_class_resource(battle_state, "style_layers", amount, log, "样式层")
		"inject_bug":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "bug", max(1, amount), log)
			_modify_intents(entry.get("target_type", "selected"), battle_state, run_state, target_index, -2 * max(1, amount), log)
		"add_case":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "case_mark", max(1, amount), log)
		"add_diff":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "diff", max(1, amount), log)
		"add_compute":
			_add_class_resource(battle_state, "compute", amount, log, "算力")
		"modify_complexity":
			_add_class_resource(battle_state, "complexity", amount, log, "复杂度")
		"modify_intent":
			_modify_intents(entry.get("target_type", "selected"), battle_state, run_state, target_index, amount, log)
		"create_card":
			_create_card(battle_state, String(params.get("card_id", "")), String(params.get("destination", "discard")), max(1, amount), log)
		"add_relic":
			_add_relic(run_state, String(params.get("relic_id", "")), log)
		"spawn_enemy":
			_spawn_enemy(battle_state, String(params.get("enemy_id", "")), log)
		"upgrade_card", "remove_card", "add_random_card", "add_random_relic", "move_card":
			log.append("事件效果已记录：%s" % effect_type)
		_:
			log.append("未实现效果：%s" % effect_type)

func _player(battle_state: Dictionary) -> Dictionary:
	return battle_state.get("player", {})

func _alive_enemies(battle_state: Dictionary) -> Array:
	return battle_state.get("enemies", []).filter(func(enemy): return int(enemy.get("current_hp", 0)) > 0)

func _target_enemy(battle_state: Dictionary, target_index: int, target_type := "selected") -> Dictionary:
	var enemies: Array = battle_state.get("enemies", [])
	if enemies.is_empty():
		return {}
	var alive := _alive_enemies(battle_state)
	if alive.is_empty():
		return {}
	if target_type == "random_enemy":
		return alive.pick_random()
	if target_type == "lowest_hp_enemy":
		alive.sort_custom(func(a, b): return int(a.get("current_hp", 0)) < int(b.get("current_hp", 0)))
		return alive[0]
	if target_type == "highest_priority_enemy":
		alive.sort_custom(func(a, b):
			var ap := int(a.get("status_list", {}).get("priority", 0))
			var bp := int(b.get("status_list", {}).get("priority", 0))
			if ap == bp:
				return int(a.get("current_hp", 0)) < int(b.get("current_hp", 0))
			return ap > bp
		)
		return alive[0]
	target_index = clamp(target_index, 0, enemies.size() - 1)
	if int(enemies[target_index].get("current_hp", 0)) <= 0:
		return alive[0]
	return enemies[target_index]

func _target_enemies(target_type: String, battle_state: Dictionary, target_index: int) -> Array:
	if target_type == "all_enemies":
		return _alive_enemies(battle_state)
	var enemy := _target_enemy(battle_state, target_index, target_type)
	return [] if enemy.is_empty() else [enemy]

func _gain_block(battle_state: Dictionary, run_state: Dictionary, amount: int, log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	var final_amount := amount
	if relics.has("relic_standing_desk") and not flags.get("standing_desk_block_used", false):
		final_amount += 2
		flags["standing_desk_block_used"] = true
		log.append("升降桌追加 2 防线")
	player["relic_runtime_flags"] = flags
	player["current_block"] = int(player.get("current_block", 0)) + final_amount
	log.append("获得 %d 防线" % final_amount)

func _damage_enemies(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, amount: int, log: Array) -> void:
	for enemy in _target_enemies(target_type, battle_state, target_index):
		_damage_enemy(enemy, battle_state, run_state, amount, log)

func _damage_enemy(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, amount: int, log: Array) -> void:
	if enemy.is_empty():
		return
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	var bonus := int(resources.get("style_layers", 0)) + int(enemy.get("status_list", {}).get("case_mark", 0))
	if run_state.get("owned_relic_ids", []).has("relic_paper_citation") and int(resources.get("complexity", 0)) >= 3:
		bonus += 3
	var damage := int(max(0, amount + bonus))
	if int(player.get("status_list", {}).get("weak", 0)) > 0:
		damage = int(floor(damage * 0.75))
	if int(enemy.get("status_list", {}).get("vulnerable", 0)) > 0:
		damage = int(ceil(damage * 1.5))
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

func _apply_status(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, status_id: String, amount: int, log: Array) -> void:
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
		for enemy in _target_enemies(target_type, battle_state, target_index):
			_enemy_status(enemy, battle_state, run_state, status_id, amount, log)

func _remove_status(target_type: String, battle_state: Dictionary, target_index: int, status_id: String) -> void:
	if target_type == "self":
		_player(battle_state).get("status_list", {}).erase(status_id)
	else:
		_target_enemy(battle_state, target_index).get("status_list", {}).erase(status_id)

func _enemy_status(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, status_id: String, amount: int, log: Array) -> void:
	if enemy.is_empty():
		return
	var statuses: Dictionary = enemy.get("status_list", {})
	statuses[status_id] = int(statuses.get(status_id, 0)) + amount
	enemy["status_list"] = statuses
	log.append("%s 获得 %s x%d" % [enemy.get("name", "敌人"), status_id, amount])
	_apply_status_relics(battle_state, run_state, enemy, status_id, amount, log)

func _add_class_resource(battle_state: Dictionary, key: String, amount: int, log: Array, label: String) -> void:
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	resources[key] = max(0, int(resources.get(key, 0)) + amount)
	player["class_resource_state"] = resources
	if amount != 0:
		log.append("%s %+d" % [label, amount])

func _modify_intents(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, amount: int, log: Array) -> void:
	for enemy in _target_enemies(target_type, battle_state, target_index):
		_modify_intent(enemy, battle_state, run_state, amount, log)

func _modify_intent(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, amount: int, log: Array) -> void:
	var intent: Dictionary = enemy.get("intent", {})
	if intent.get("intent_type", "") == "attack":
		intent["amount"] = max(0, int(intent.get("amount", 0)) + amount)
		enemy["intent"] = intent
		log.append("%s 攻击意图 %+d" % [enemy.get("name", "敌人"), amount])
	_apply_modify_intent_relics(battle_state, run_state, log)

func _apply_status_relics(battle_state: Dictionary, run_state: Dictionary, enemy: Dictionary, status_id: String, amount: int, log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if status_id == "bug" and relics.has("relic_tester_automation_framework") and not flags.get("automation_framework_used", false):
		flags["automation_framework_used"] = true
		_enemy_status(enemy, battle_state, run_state, "case_mark", 1, log)
	if status_id == "requirement_change" and relics.has("relic_pm_review_minutes") and not flags.get("pm_review_minutes_used", false):
		flags["pm_review_minutes_used"] = true
		player["relic_runtime_flags"] = flags
		_gain_block(battle_state, run_state, 4, log)
		_draw_cards(battle_state, 1, log)
	else:
		player["relic_runtime_flags"] = flags

func _apply_modify_intent_relics(battle_state: Dictionary, run_state: Dictionary, log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if relics.has("relic_gantt_roadmap") and not flags.get("gantt_roadmap_used", false):
		flags["gantt_roadmap_used"] = true
		player["relic_runtime_flags"] = flags
		_draw_cards(battle_state, 1, log)
	if relics.has("relic_pm_review_minutes") and not flags.get("pm_review_minutes_used", false):
		flags = player.get("relic_runtime_flags", {})
		flags["pm_review_minutes_used"] = true
		player["relic_runtime_flags"] = flags
		_gain_block(battle_state, run_state, 4, log)
		_draw_cards(battle_state, 1, log)
	else:
		player["relic_runtime_flags"] = flags

func _apply_component_relics(battle_state: Dictionary, run_state: Dictionary, log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	if run_state.get("owned_relic_ids", []).has("relic_figma_library") and not flags.get("figma_library_used", false):
		flags["figma_library_used"] = true
		_add_class_resource(battle_state, "components", 1, log, "Figma组件库复制组件")
	player["relic_runtime_flags"] = flags

func _create_card(battle_state: Dictionary, card_id: String, destination: String, amount: int, log: Array) -> void:
	if card_id.is_empty():
		return
	var player := _player(battle_state)
	var pile_name := "discard_pile"
	if destination == "hand":
		pile_name = "hand"
	elif destination == "draw":
		pile_name = "draw_pile"
	for i in range(amount):
		player[pile_name].append(card_id)
	log.append("生成卡牌 %s x%d" % [card_id, amount])

func _add_relic(run_state: Dictionary, relic_id: String, log: Array) -> void:
	if relic_id.is_empty():
		return
	var relics: Array = run_state.get("owned_relic_ids", [])
	if not relics.has(relic_id):
		relics.append(relic_id)
	run_state["owned_relic_ids"] = relics
	log.append("获得遗物 %s" % relic_id)

func _spawn_enemy(battle_state: Dictionary, enemy_id: String, log: Array) -> void:
	var enemy_def: Dictionary = config_service.get_def("enemies", enemy_id)
	if enemy_def.is_empty():
		return
	battle_state["enemies"].append({
		"enemy_def_id": enemy_id,
		"name": enemy_def.get("name", enemy_id),
		"max_hp": int(enemy_def.get("base_hp", 20)),
		"current_hp": int(enemy_def.get("base_hp", 20)),
		"current_block": 0,
		"phase_index": 0,
		"intent": {},
		"status_list": {},
		"runtime_flags": {},
	})
	log.append("增援出现：%s" % enemy_def.get("name", enemy_id))
