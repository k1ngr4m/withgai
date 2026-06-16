class_name EffectExecutor
extends RefCounted

var config_service: ConfigService

func setup(p_config_service: ConfigService) -> void:
	config_service = p_config_service

func execute(entries: Array, battle_state: Dictionary, run_state: Dictionary, target_index: int, battle_log: Array) -> void:
	for entry in entries:
		_execute_entry(entry, battle_state, run_state, target_index, battle_log)

func _execute_entry(entry: Dictionary, battle_state: Dictionary, run_state: Dictionary, target_index: int, battle_log: Array) -> void:
	var effect_type := String(entry.get("effect_type", ""))
	var params: Dictionary = entry.get("params", {})
	var amount := int(params.get("amount", 0))
	match effect_type:
		"gain_block":
			_gain_block(battle_state, run_state, amount, battle_log)
		"deal_damage":
			_damage_enemies(entry.get("target_type", "selected"), battle_state, run_state, target_index, amount, battle_log)
		"draw_cards":
			_draw_cards(battle_state, amount, battle_log)
		"gain_energy":
			_player(battle_state)["current_energy"] = int(_player(battle_state).get("current_energy", 0)) + amount
		"apply_status":
			_apply_status(entry.get("target_type", "selected"), battle_state, run_state, target_index, String(params.get("status_id", "")), int(params.get("amount", 1)), battle_log)
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
			_add_class_resource(battle_state, "services", max(1, amount), battle_log, "部署服务")
		"add_cache":
			_add_class_resource(battle_state, "cache", amount, battle_log, "缓存")
		"add_component":
			_add_class_resource(battle_state, "components", amount, battle_log, "组件")
			_apply_component_relics(battle_state, run_state, battle_log)
		"add_style_layer":
			_add_class_resource(battle_state, "style_layers", amount, battle_log, "样式层")
		"inject_bug":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				var bug_amount := _bug_amount_with_diff(enemy, battle_state, max(1, amount), battle_log)
				_enemy_status(enemy, battle_state, run_state, "bug", bug_amount, battle_log)
				_modify_intent(enemy, battle_state, run_state, -2 * bug_amount, battle_log)
		"add_case":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "case_mark", max(1, amount), battle_log)
		"add_diff":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "diff", max(1, amount), battle_log)
		"add_compute":
			_add_class_resource(battle_state, "compute", amount, battle_log, "算力")
		"modify_complexity":
			_add_class_resource(battle_state, "complexity", amount, battle_log, "复杂度")
		"modify_intent":
			_modify_intents(entry.get("target_type", "selected"), battle_state, run_state, target_index, amount, battle_log)
		"create_card":
			_create_card(battle_state, String(params.get("card_id", "")), String(params.get("destination", "discard")), max(1, amount), battle_log)
		"move_card":
			_move_card(
				battle_state,
				String(params.get("source", params.get("from", "discard"))),
				String(params.get("destination", params.get("to", "draw"))),
				max(1, amount),
				String(params.get("card_id", "")),
				battle_log
			)
		"add_relic":
			_add_relic(run_state, String(params.get("relic_id", "")), battle_log)
		"spawn_enemy":
			_spawn_enemy(battle_state, String(params.get("enemy_id", "")), battle_log)
		"upgrade_card":
			_upgrade_run_cards(run_state, battle_state, max(1, amount), String(params.get("card_id", "")), battle_log)
		"remove_card":
			_remove_run_cards(run_state, max(1, amount), String(params.get("card_id", "")), battle_log)
		"add_random_card":
			_add_random_run_cards(run_state, max(1, amount), battle_log)
		"add_random_relic":
			_add_random_run_relics(run_state, max(1, amount), battle_log)
		_:
			battle_log.append("未实现效果：%s" % effect_type)

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

func _gain_block(battle_state: Dictionary, run_state: Dictionary, amount: int, battle_log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	var final_amount := amount
	if relics.has("relic_standing_desk") and not flags.get("standing_desk_block_used", false):
		final_amount += 2
		flags["standing_desk_block_used"] = true
		battle_log.append("升降桌追加 2 防线")
	player["relic_runtime_flags"] = flags
	player["current_block"] = int(player.get("current_block", 0)) + final_amount
	battle_log.append("获得 %d 防线" % final_amount)

func _damage_enemies(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, amount: int, battle_log: Array) -> void:
	var targets := _target_enemies(target_type, battle_state, target_index)
	var style_layer_bonus := _style_layer_count(_player(battle_state))
	for enemy in targets:
		_damage_enemy(enemy, battle_state, run_state, amount, battle_log, style_layer_bonus)
	if not targets.is_empty() and style_layer_bonus > 0:
		_consume_style_layer(_player(battle_state), battle_log)

func _damage_enemy(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, amount: int, battle_log: Array, style_layer_bonus := 0) -> void:
	if enemy.is_empty():
		return
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	var bonus := style_layer_bonus + int(enemy.get("status_list", {}).get("case_mark", 0))
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
	battle_log.append("对 %s 造成 %d 伤害" % [enemy.get("name", "敌人"), damage])

func _style_layer_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("style_layers", 0)), int(statuses.get("style_layer", 0)))

func _consume_style_layer(player: Dictionary, battle_log: Array) -> void:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	if int(resources.get("style_layers", 0)) > 0:
		resources["style_layers"] = max(0, int(resources.get("style_layers", 0)) - 1)
	if int(statuses.get("style_layer", 0)) > 0:
		statuses["style_layer"] = max(0, int(statuses.get("style_layer", 0)) - 1)
	player["class_resource_state"] = resources
	player["status_list"] = statuses
	battle_log.append("样式层消耗 1")

func _bug_amount_with_diff(enemy: Dictionary, battle_state: Dictionary, base_amount: int, battle_log: Array) -> int:
	var statuses: Dictionary = enemy.get("status_list", {})
	if int(statuses.get("diff", 0)) <= 0:
		return base_amount
	statuses["diff"] = max(0, int(statuses.get("diff", 0)) - 1)
	enemy["status_list"] = statuses
	_sync_status_resource(battle_state, "diff", -1, battle_log)
	battle_log.append("%s 的 Diff 被复现，Bug +1" % enemy.get("name", "敌人"))
	return base_amount + 1

func _draw_cards(battle_state: Dictionary, amount: int, battle_log: Array) -> void:
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
		battle_log.append("抽 %d 张牌" % amount)

func _apply_status(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, status_id: String, amount: int, battle_log: Array) -> void:
	if status_id.is_empty():
		return
	if target_type == "self":
		var player := _player(battle_state)
		var statuses: Dictionary = player.get("status_list", {})
		statuses[status_id] = int(statuses.get(status_id, 0)) + amount
		player["status_list"] = statuses
		_sync_status_resource(battle_state, status_id, amount, battle_log)
	else:
		for enemy in _target_enemies(target_type, battle_state, target_index):
			_enemy_status(enemy, battle_state, run_state, status_id, amount, battle_log)

func _remove_status(target_type: String, battle_state: Dictionary, target_index: int, status_id: String) -> void:
	if target_type == "self":
		_player(battle_state).get("status_list", {}).erase(status_id)
	else:
		_target_enemy(battle_state, target_index).get("status_list", {}).erase(status_id)

func _enemy_status(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, status_id: String, amount: int, battle_log: Array) -> void:
	if enemy.is_empty():
		return
	var statuses: Dictionary = enemy.get("status_list", {})
	statuses[status_id] = int(statuses.get(status_id, 0)) + amount
	enemy["status_list"] = statuses
	battle_log.append("%s 获得 %s x%d" % [enemy.get("name", "敌人"), status_id, amount])
	_sync_status_resource(battle_state, status_id, amount, battle_log)
	_apply_status_relics(battle_state, run_state, enemy, status_id, amount, battle_log)

func _sync_status_resource(battle_state: Dictionary, status_id: String, amount: int, battle_log: Array) -> void:
	var resource_key := ""
	var label := ""
	match status_id:
		"service_online":
			resource_key = "services"
			label = "服务"
		"cache":
			resource_key = "cache"
			label = "缓存"
		"component":
			resource_key = "components"
			label = "组件"
		"style_layer":
			resource_key = "style_layers"
			label = "样式层"
		"bug":
			resource_key = "bugs"
			label = "Bug"
		"case_mark":
			resource_key = "cases"
			label = "用例"
		"diff":
			resource_key = "diff_tags"
			label = "Diff"
		"compute":
			resource_key = "compute"
			label = "算力"
		"complexity":
			resource_key = "complexity"
			label = "复杂度"
		"requirement_change":
			resource_key = "requirement_change_marks"
			label = "需求变更"
		"priority":
			resource_key = "priority_targets"
			label = "优先级"
		"performance":
			resource_key = "performance"
			label = "绩效"
		"optimization_target":
			resource_key = "optimization_targets"
			label = "优化名单"
	if resource_key.is_empty():
		return
	_add_class_resource(battle_state, resource_key, amount, battle_log, label)

func _add_class_resource(battle_state: Dictionary, key: String, amount: int, battle_log: Array, label: String) -> void:
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	resources[key] = max(0, int(resources.get(key, 0)) + amount)
	player["class_resource_state"] = resources
	if amount != 0:
		battle_log.append("%s %+d" % [label, amount])

func _modify_intents(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, amount: int, battle_log: Array) -> void:
	for enemy in _target_enemies(target_type, battle_state, target_index):
		_modify_intent(enemy, battle_state, run_state, amount, battle_log)

func _modify_intent(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, amount: int, battle_log: Array) -> void:
	var intent: Dictionary = enemy.get("intent", {})
	if intent.get("intent_type", "") == "attack":
		intent["amount"] = max(0, int(intent.get("amount", 0)) + amount)
		enemy["intent"] = intent
		battle_log.append("%s 攻击意图 %+d" % [enemy.get("name", "敌人"), amount])
	_apply_modify_intent_relics(battle_state, run_state, battle_log)

func _apply_status_relics(battle_state: Dictionary, run_state: Dictionary, enemy: Dictionary, status_id: String, amount: int, battle_log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if status_id == "bug" and relics.has("relic_tester_automation_framework") and not flags.get("automation_framework_used", false):
		flags["automation_framework_used"] = true
		_enemy_status(enemy, battle_state, run_state, "case_mark", 1, battle_log)
	if status_id == "bug" and relics.has("relic_error_log_repo"):
		_damage_enemy(enemy, battle_state, run_state, 3 * max(1, amount), battle_log)
		battle_log.append("报错日志仓库追加惩罚")
	if status_id == "requirement_change" and relics.has("relic_pm_review_minutes") and not flags.get("pm_review_minutes_used", false):
		flags["pm_review_minutes_used"] = true
		player["relic_runtime_flags"] = flags
		_gain_block(battle_state, run_state, 4, battle_log)
		_draw_cards(battle_state, 1, battle_log)
	else:
		player["relic_runtime_flags"] = flags

func _apply_modify_intent_relics(battle_state: Dictionary, run_state: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if relics.has("relic_gantt_roadmap") and not flags.get("gantt_roadmap_used", false):
		flags["gantt_roadmap_used"] = true
		player["relic_runtime_flags"] = flags
		_draw_cards(battle_state, 1, battle_log)
	if relics.has("relic_pm_review_minutes") and not flags.get("pm_review_minutes_used", false):
		flags = player.get("relic_runtime_flags", {})
		flags["pm_review_minutes_used"] = true
		player["relic_runtime_flags"] = flags
		_gain_block(battle_state, run_state, 4, battle_log)
		_draw_cards(battle_state, 1, battle_log)
	else:
		player["relic_runtime_flags"] = flags

func _apply_component_relics(battle_state: Dictionary, run_state: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	if run_state.get("owned_relic_ids", []).has("relic_figma_library") and not flags.get("figma_library_used", false):
		flags["figma_library_used"] = true
		_add_class_resource(battle_state, "components", 1, battle_log, "Figma组件库复制组件")
	player["relic_runtime_flags"] = flags

func _create_card(battle_state: Dictionary, card_id: String, destination: String, amount: int, battle_log: Array) -> void:
	if card_id.is_empty():
		return
	var player := _player(battle_state)
	var pile_name := _pile_key(destination, "discard_pile")
	for i in range(amount):
		player[pile_name].append(card_id)
	battle_log.append("生成卡牌 %s x%d" % [card_id, amount])

func _move_card(battle_state: Dictionary, source: String, destination: String, amount: int, card_id: String, battle_log: Array) -> void:
	var source_key := _pile_key(source, "discard_pile")
	var destination_key := _pile_key(destination, "draw_pile")
	if source_key == destination_key:
		return
	var player := _player(battle_state)
	var source_pile: Array = player.get(source_key, [])
	var destination_pile: Array = player.get(destination_key, [])
	var moved := 0
	for i in range(amount):
		var source_index := _find_card_index(source_pile, card_id)
		if source_index < 0:
			break
		var moved_card := String(source_pile[source_index])
		source_pile.remove_at(source_index)
		destination_pile.append(moved_card)
		moved += 1
	player[source_key] = source_pile
	player[destination_key] = destination_pile
	if moved > 0:
		battle_log.append("移动卡牌 %s -> %s x%d" % [source_key, destination_key, moved])

func _pile_key(alias: String, fallback: String) -> String:
	match alias:
		"hand":
			return "hand"
		"draw", "draw_pile":
			return "draw_pile"
		"discard", "discard_pile":
			return "discard_pile"
		"exhaust", "exhaust_pile":
			return "exhaust_pile"
		_:
			return fallback

func _find_card_index(pile: Array, card_id: String) -> int:
	if card_id.is_empty():
		return pile.size() - 1
	for i in range(pile.size()):
		if String(pile[i]) == card_id:
			return i
	return -1

func _add_relic(run_state: Dictionary, relic_id: String, battle_log: Array) -> void:
	if relic_id.is_empty():
		return
	var relics: Array = run_state.get("owned_relic_ids", [])
	if not relics.has(relic_id):
		relics.append(relic_id)
	run_state["owned_relic_ids"] = relics
	battle_log.append("获得遗物 %s" % relic_id)

func _add_random_run_cards(run_state: Dictionary, amount: int, battle_log: Array) -> void:
	var candidates: Array = config_service.cards_for_class(String(run_state.get("selected_class_id", "")), true, false)
	candidates.shuffle()
	var deck_state: Dictionary = run_state.get("deck_state", {})
	var deck: Array = deck_state.get("master_deck", [])
	var added := 0
	for card in candidates:
		if added >= amount:
			break
		var card_id := String(card.get("id", ""))
		if card_id.is_empty():
			continue
		deck.append(card_id)
		added += 1
	deck_state["master_deck"] = deck
	run_state["deck_state"] = deck_state
	if added > 0:
		battle_log.append("获得随机卡牌 x%d" % added)

func _add_random_run_relics(run_state: Dictionary, amount: int, battle_log: Array) -> void:
	var candidates: Array = config_service.relics_for_class(String(run_state.get("selected_class_id", "")), false)
	candidates.shuffle()
	var owned: Array = run_state.get("owned_relic_ids", [])
	var added := 0
	for relic in candidates:
		if added >= amount:
			break
		var relic_id := String(relic.get("id", ""))
		if relic_id.is_empty() or owned.has(relic_id):
			continue
		owned.append(relic_id)
		added += 1
	run_state["owned_relic_ids"] = owned
	if added > 0:
		battle_log.append("获得随机遗物 x%d" % added)

func _remove_run_cards(run_state: Dictionary, amount: int, card_id: String, battle_log: Array) -> void:
	var deck_state: Dictionary = run_state.get("deck_state", {})
	var deck: Array = deck_state.get("master_deck", [])
	var removed_cards: Array = deck_state.get("removed_cards", [])
	var removed := 0
	for i in range(amount):
		var index := _find_card_index(deck, card_id)
		if index < 0:
			break
		var removed_card := String(deck[index])
		deck.remove_at(index)
		removed_cards.append(removed_card)
		removed += 1
	deck_state["master_deck"] = deck
	deck_state["removed_cards"] = removed_cards
	run_state["deck_state"] = deck_state
	if removed > 0:
		battle_log.append("移除卡牌 x%d" % removed)

func _upgrade_run_cards(run_state: Dictionary, battle_state: Dictionary, amount: int, card_id: String, battle_log: Array) -> void:
	var deck_state: Dictionary = run_state.get("deck_state", {})
	var deck: Array = deck_state.get("master_deck", [])
	var upgraded: Array = deck_state.get("upgraded_cards", [])
	var upgraded_battle: Array = battle_state.get("upgraded_card_ids", [])
	var upgraded_count := 0
	if not card_id.is_empty():
		if deck.has(card_id):
			upgraded_count += _upgrade_one_card(card_id, upgraded, upgraded_battle)
	else:
		for item in deck:
			if upgraded_count >= amount:
				break
			upgraded_count += _upgrade_one_card(String(item), upgraded, upgraded_battle)
	deck_state["upgraded_cards"] = upgraded
	run_state["deck_state"] = deck_state
	battle_state["upgraded_card_ids"] = upgraded_battle
	if upgraded_count > 0:
		battle_log.append("升级卡牌 x%d" % upgraded_count)

func _upgrade_one_card(card_id: String, upgraded: Array, upgraded_battle: Array) -> int:
	if card_id.is_empty() or upgraded.has(card_id):
		return 0
	upgraded.append(card_id)
	if not upgraded_battle.has(card_id):
		upgraded_battle.append(card_id)
	return 1

func _spawn_enemy(battle_state: Dictionary, enemy_id: String, battle_log: Array) -> void:
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
	battle_log.append("增援出现：%s" % enemy_def.get("name", enemy_id))
