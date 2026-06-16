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
			_damage_enemies(entry.get("target_type", "selected"), battle_state, run_state, target_index, amount, params, battle_log)
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
		"circuit_breaker":
			_circuit_breaker(battle_state, run_state, params, battle_log)
		"add_cache":
			_add_cache(battle_state, amount, params, battle_log)
		"service_degrade":
			_service_degrade(battle_state, run_state, params, battle_log)
		"add_component":
			_add_component(battle_state, run_state, amount, params, battle_log)
		"add_style_layer":
			_add_class_resource(battle_state, "style_layers", amount, battle_log, "样式层")
		"inject_bug":
			_inject_bug(entry.get("target_type", "selected"), battle_state, run_state, target_index, params, battle_log)
		"upgrade_bug":
			_upgrade_bug(entry.get("target_type", "selected"), battle_state, run_state, target_index, max(1, amount), battle_log)
		"confirm_regression":
			_confirm_regression(entry.get("target_type", "selected"), battle_state, run_state, target_index, max(1, amount), int(params.get("draw_amount", 1)), battle_log)
		"boundary_check":
			_boundary_check(entry.get("target_type", "selected"), battle_state, run_state, target_index, params, battle_log)
		"add_case":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "case_mark", max(1, amount), battle_log)
		"add_diff":
			for enemy in _target_enemies(entry.get("target_type", "selected"), battle_state, target_index):
				_enemy_status(enemy, battle_state, run_state, "diff", max(1, amount), battle_log)
		"add_compute":
			_add_compute(battle_state, run_state, amount, battle_log)
		"modify_complexity":
			_add_class_resource(battle_state, "complexity", amount, battle_log, "复杂度")
		"compress_complexity":
			_compress_complexity(battle_state, run_state, params, battle_log)
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

func _damage_enemies(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, amount: int, params: Dictionary, battle_log: Array) -> void:
	var targets := _target_enemies(target_type, battle_state, target_index)
	var player := _player(battle_state)
	var style_layer_count: int = _style_layer_count(player)
	var style_layers_as_hits: bool = bool(params.get("style_layer_hits", false))
	var style_layer_bonus: int = 0 if style_layers_as_hits else style_layer_count
	var hit_count: int = int(max(1, int(params.get("hits", 1))))
	if style_layers_as_hits:
		hit_count += style_layer_count * int(max(1, int(params.get("style_layer_hit_multiplier", 1))))
	var backend_context := _backend_damage_context(player, params)
	var algorithm_context := _algorithm_damage_context(player, battle_state, params)
	var cards_played_bonus := _cards_played_damage_bonus(player, params)
	var resource_bonus := int(backend_context.get("bonus", 0)) + int(algorithm_context.get("bonus", 0)) + cards_played_bonus
	for enemy in targets:
		for _hit_index in range(hit_count):
			_damage_enemy(enemy, battle_state, run_state, amount, battle_log, style_layer_bonus, resource_bonus, params)
	if not targets.is_empty() and style_layers_as_hits and bool(params.get("consume_all_style_layers", false)) and style_layer_count > 0:
		_consume_style_layers(player, style_layer_count, battle_log)
	elif not targets.is_empty() and style_layer_bonus > 0:
		_consume_style_layer(player, battle_log)
	if not targets.is_empty() and int(backend_context.get("consume_cache", 0)) > 0:
		_consume_cache(player, int(backend_context.get("consume_cache", 0)), battle_log)
	if not targets.is_empty() and int(algorithm_context.get("consume_compute", 0)) > 0:
		_consume_compute(player, int(algorithm_context.get("consume_compute", 0)), battle_log)

func _damage_enemy(enemy: Dictionary, battle_state: Dictionary, run_state: Dictionary, amount: int, battle_log: Array, style_layer_bonus := 0, resource_bonus := 0, params: Dictionary = {}) -> void:
	if enemy.is_empty():
		return
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	var bonus := style_layer_bonus + resource_bonus + int(enemy.get("status_list", {}).get("case_mark", 0)) + _target_status_damage_bonus(enemy, params)
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

func _target_status_damage_bonus(enemy: Dictionary, params: Dictionary) -> int:
	var statuses: Dictionary = enemy.get("status_list", {})
	var bonus := 0
	bonus += int(statuses.get("bug", 0)) * int(params.get("bug_multiplier", 0))
	bonus += int(statuses.get("case_mark", 0)) * int(params.get("case_multiplier", 0))
	bonus += int(statuses.get("diff", 0)) * int(params.get("diff_multiplier", 0))
	return bonus

func _cards_played_damage_bonus(player: Dictionary, params: Dictionary) -> int:
	var multiplier := int(params.get("cards_played_multiplier", 0))
	if multiplier <= 0:
		return 0
	return int(player.get("cards_played_this_turn", 0)) * multiplier

func _style_layer_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("style_layers", 0)), int(statuses.get("style_layer", 0)))

func _consume_style_layer(player: Dictionary, battle_log: Array) -> void:
	_consume_style_layers(player, 1, battle_log)

func _consume_style_layers(player: Dictionary, amount: int, battle_log: Array) -> void:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	if int(resources.get("style_layers", 0)) > 0:
		resources["style_layers"] = max(0, int(resources.get("style_layers", 0)) - amount)
	if int(statuses.get("style_layer", 0)) > 0:
		statuses["style_layer"] = max(0, int(statuses.get("style_layer", 0)) - amount)
	player["class_resource_state"] = resources
	player["status_list"] = statuses
	battle_log.append("样式层消耗 %d" % amount)

func _backend_damage_context(player: Dictionary, params: Dictionary) -> Dictionary:
	var result := { "bonus": 0, "consume_cache": 0 }
	if not bool(params.get("consume_cache", false)):
		return result
	var cache := _cache_count(player)
	if cache > 0:
		result["bonus"] = cache * int(params.get("cache_multiplier", 3))
		result["consume_cache"] = cache
	return result

func _cache_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("cache", 0)), int(statuses.get("cache", 0)))

func _consume_cache(player: Dictionary, amount: int, battle_log: Array) -> void:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	if int(resources.get("cache", 0)) > 0:
		resources["cache"] = max(0, int(resources.get("cache", 0)) - amount)
	if int(statuses.get("cache", 0)) > 0:
		statuses["cache"] = max(0, int(statuses.get("cache", 0)) - amount)
	player["class_resource_state"] = resources
	player["status_list"] = statuses
	battle_log.append("缓存回写 %d" % amount)

func _algorithm_damage_context(player: Dictionary, battle_state: Dictionary, params: Dictionary) -> Dictionary:
	var result := { "bonus": 0, "consume_compute": 0 }
	var uses_x_energy := bool(params.get("x_energy_scaling", false))
	var consumes_compute := bool(params.get("consume_compute", false))
	var complexity_multiplier := int(params.get("complexity_multiplier", 0))
	if not uses_x_energy and not consumes_compute and complexity_multiplier <= 0:
		return result
	var play_context: Dictionary = battle_state.get("last_play_context", {})
	if uses_x_energy and bool(play_context.get("is_x_cost", false)):
		result["bonus"] = int(result.get("bonus", 0)) + int(play_context.get("cost_paid", 0)) * int(params.get("x_energy_multiplier", 4))
	var compute := _compute_count(player)
	if consumes_compute and compute > 0:
		result["bonus"] = int(result.get("bonus", 0)) + compute * int(params.get("compute_multiplier", 3))
		result["consume_compute"] = compute
	if complexity_multiplier > 0:
		result["bonus"] = int(result.get("bonus", 0)) + _complexity_count(player) * complexity_multiplier
	return result

func _compute_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("compute", 0)), int(statuses.get("compute", 0)))

func _complexity_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("complexity", 0)), int(statuses.get("complexity", 0)))

func _service_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("services", 0)), int(statuses.get("service_online", 0)))

func _consume_compute(player: Dictionary, amount: int, battle_log: Array) -> void:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	if int(resources.get("compute", 0)) > 0:
		resources["compute"] = max(0, int(resources.get("compute", 0)) - amount)
	if int(statuses.get("compute", 0)) > 0:
		statuses["compute"] = max(0, int(statuses.get("compute", 0)) - amount)
	player["class_resource_state"] = resources
	player["status_list"] = statuses
	battle_log.append("算力释放 %d" % amount)

func _consume_complexity(player: Dictionary, amount: int, battle_log: Array) -> void:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	if int(resources.get("complexity", 0)) > 0:
		resources["complexity"] = max(0, int(resources.get("complexity", 0)) - amount)
	if int(statuses.get("complexity", 0)) > 0:
		statuses["complexity"] = max(0, int(statuses.get("complexity", 0)) - amount)
	player["class_resource_state"] = resources
	player["status_list"] = statuses
	battle_log.append("复杂度压缩 %d" % amount)

func _compress_complexity(battle_state: Dictionary, run_state: Dictionary, params: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	var available: int = _complexity_count(player)
	if available <= 0:
		battle_log.append("没有可压缩复杂度")
		return
	var converted: int = min(available, max(1, int(params.get("amount", 1))))
	_consume_complexity(player, converted, battle_log)
	var compute_gain: int = converted * max(0, int(params.get("compute_per_complexity", 1)))
	var block_gain: int = converted * max(0, int(params.get("block_per_complexity", 0)))
	if compute_gain > 0:
		_add_class_resource(battle_state, "compute", compute_gain, battle_log, "压缩算力")
	if block_gain > 0:
		_gain_block(battle_state, run_state, block_gain, battle_log)

func _bug_amount_with_diff(enemy: Dictionary, battle_state: Dictionary, base_amount: int, battle_log: Array) -> int:
	var statuses: Dictionary = enemy.get("status_list", {})
	if int(statuses.get("diff", 0)) <= 0:
		return base_amount
	statuses["diff"] = max(0, int(statuses.get("diff", 0)) - 1)
	enemy["status_list"] = statuses
	_sync_status_resource(battle_state, "diff", -1, battle_log)
	battle_log.append("%s 的 Diff 被复现，Bug +1" % enemy.get("name", "敌人"))
	return base_amount + 1

func _inject_bug(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, params: Dictionary, battle_log: Array) -> void:
	var base_amount: int = max(1, int(params.get("amount", 1)))
	var hit_count: int = max(1, int(params.get("hits", 1)))
	for enemy in _target_enemies(target_type, battle_state, target_index):
		var total_bug := 0
		for _hit_index in range(hit_count):
			var bug_amount := _bug_amount_with_diff(enemy, battle_state, base_amount, battle_log)
			total_bug += bug_amount
			_enemy_status(enemy, battle_state, run_state, "bug", bug_amount, battle_log)
			_modify_intent(enemy, battle_state, run_state, -2 * bug_amount, battle_log)
		if hit_count > 1:
			battle_log.append("%s 连续注入 Bug x%d，总层数 +%d" % [enemy.get("name", "敌人"), hit_count, total_bug])

func _upgrade_bug(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, amount: int, battle_log: Array) -> void:
	for enemy in _target_enemies(target_type, battle_state, target_index):
		var statuses: Dictionary = enemy.get("status_list", {})
		if int(statuses.get("bug", 0)) <= 0:
			battle_log.append("%s 没有可升级 Bug" % enemy.get("name", "敌人"))
			continue
		_enemy_status(enemy, battle_state, run_state, "bug", amount, battle_log)
		_modify_intent(enemy, battle_state, run_state, -2 * amount, battle_log)
		battle_log.append("%s 的 Bug 升级 +%d" % [enemy.get("name", "敌人"), amount])

func _confirm_regression(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, diff_amount: int, draw_amount: int, battle_log: Array) -> void:
	for enemy in _target_enemies(target_type, battle_state, target_index):
		var statuses: Dictionary = enemy.get("status_list", {})
		if int(statuses.get("case_mark", 0)) <= 0:
			battle_log.append("%s 没有可确认用例" % enemy.get("name", "敌人"))
			continue
		_enemy_status(enemy, battle_state, run_state, "diff", diff_amount, battle_log)
		_draw_cards(battle_state, max(0, draw_amount), battle_log)
		battle_log.append("%s 回归确认通过，Diff +%d" % [enemy.get("name", "敌人"), diff_amount])

func _boundary_check(target_type: String, battle_state: Dictionary, run_state: Dictionary, target_index: int, params: Dictionary, battle_log: Array) -> void:
	for enemy in _target_enemies(target_type, battle_state, target_index):
		var base_cases: int = max(1, int(params.get("amount", 1)))
		var extra_cases := 0
		if _boundary_check_bonus_applies(enemy, params):
			extra_cases = max(0, int(params.get("bonus_amount", 1)))
		_enemy_status(enemy, battle_state, run_state, "case_mark", base_cases + extra_cases, battle_log)
		if extra_cases > 0:
			battle_log.append("%s 命中边界条件，用例 +%d" % [enemy.get("name", "敌人"), extra_cases])

func _boundary_check_bonus_applies(enemy: Dictionary, params: Dictionary) -> bool:
	var max_hp: int = max(1, int(enemy.get("max_hp", enemy.get("current_hp", 1))))
	var current_hp: int = int(enemy.get("current_hp", max_hp))
	var low_hp_percent: int = clamp(int(params.get("low_hp_percent", 50)), 1, 100)
	if current_hp * 100 <= max_hp * low_hp_percent:
		return true
	var high_attack_threshold: int = max(1, int(params.get("high_attack_threshold", 10)))
	var intent: Dictionary = enemy.get("intent", {})
	return _enemy_intent_attack_amount(intent) >= high_attack_threshold

func _enemy_intent_attack_amount(intent: Dictionary) -> int:
	match String(intent.get("intent_type", "")):
		"attack":
			return int(intent.get("amount", 0))
		"multi_attack":
			return int(intent.get("amount", 0)) * max(1, int(intent.get("hits", 1)))
	return 0

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
		_sync_status_resource(battle_state, status_id, amount, battle_log, run_state)
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
	_sync_status_resource(battle_state, status_id, amount, battle_log, run_state)
	_apply_case_matrix(battle_state, run_state, enemy, status_id, battle_log)
	_apply_status_relics(battle_state, run_state, enemy, status_id, amount, battle_log)
	_apply_scope_spread(battle_state, run_state, enemy, status_id, battle_log)

func _apply_case_matrix(battle_state: Dictionary, run_state: Dictionary, enemy: Dictionary, status_id: String, battle_log: Array) -> void:
	if status_id != "case_mark":
		return
	var player := _player(battle_state)
	var statuses: Dictionary = player.get("status_list", {})
	var case_matrix_stacks := int(statuses.get("case_matrix", 0))
	if case_matrix_stacks <= 0:
		return
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	if bool(flags.get("case_matrix_used_this_turn", false)):
		return
	flags["case_matrix_used_this_turn"] = true
	player["relic_runtime_flags"] = flags
	var params: Dictionary = config_service.get_def("statuses", "case_matrix").get("params", {})
	var extra_cases: int = case_matrix_stacks * max(1, int(params.get("case_amount", 1)))
	var enemy_statuses: Dictionary = enemy.get("status_list", {})
	enemy_statuses["case_mark"] = int(enemy_statuses.get("case_mark", 0)) + extra_cases
	enemy["status_list"] = enemy_statuses
	_sync_status_resource(battle_state, "case_mark", extra_cases, battle_log, run_state)
	battle_log.append("用例矩阵追加用例 +%d" % extra_cases)

func _apply_scope_spread(battle_state: Dictionary, run_state: Dictionary, source_enemy: Dictionary, status_id: String, battle_log: Array) -> void:
	if status_id != "requirement_change":
		return
	var player := _player(battle_state)
	if _scope_spread_count(player) <= 0:
		return
	var target := _first_other_alive_enemy(battle_state, source_enemy)
	if target.is_empty():
		return
	var params: Dictionary = config_service.get_def("statuses", "scope_spread").get("params", {})
	var spread_amount: int = max(1, int(params.get("spread_amount", 1)))
	var statuses: Dictionary = target.get("status_list", {})
	statuses["requirement_change"] = int(statuses.get("requirement_change", 0)) + spread_amount
	target["status_list"] = statuses
	_sync_status_resource(battle_state, "requirement_change", spread_amount, battle_log, run_state)
	battle_log.append("范围蔓延：%s 也获得需求变更 x%d" % [target.get("name", "敌人"), spread_amount])

func _scope_spread_count(player: Dictionary) -> int:
	var statuses: Dictionary = player.get("status_list", {})
	return int(statuses.get("scope_spread", 0))

func _first_other_alive_enemy(battle_state: Dictionary, source_enemy: Dictionary) -> Dictionary:
	for enemy in _alive_enemies(battle_state):
		if not is_same(enemy, source_enemy):
			return enemy
	return {}

func _sync_status_resource(battle_state: Dictionary, status_id: String, amount: int, battle_log: Array, run_state: Dictionary = {}) -> void:
	var resource_key := ""
	var label := ""
	match status_id:
		"service_online":
			resource_key = "services"
			label = "服务"
		"cache":
			resource_key = "cache"
			label = "缓存"
		"request_queue":
			resource_key = "requests"
			label = "请求"
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
	if resource_key == "compute":
		_add_compute(battle_state, run_state, amount, battle_log)
		return
	_add_class_resource(battle_state, resource_key, amount, battle_log, label)

func _add_compute(battle_state: Dictionary, run_state: Dictionary, amount: int, battle_log: Array) -> void:
	_add_class_resource(battle_state, "compute", amount, battle_log, "算力")
	if amount > 0:
		_add_compute_complexity(battle_state, amount, battle_log)
		_apply_compute_relics(battle_state, run_state, battle_log)

func _add_cache(battle_state: Dictionary, amount: int, effect_params: Dictionary, battle_log: Array) -> void:
	var cache_amount: int = amount + _cache_from_damage_taken(battle_state, effect_params)
	_add_class_resource(battle_state, "cache", cache_amount, battle_log, "缓存")
	if cache_amount <= 0:
		return
	var player := _player(battle_state)
	var statuses: Dictionary = player.get("status_list", {})
	var sharding_stacks := int(statuses.get("sharding", 0))
	if sharding_stacks <= 0:
		return
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	if bool(flags.get("sharding_cache_used_this_turn", false)):
		return
	var sharding_params: Dictionary = config_service.get_def("statuses", "sharding").get("params", {})
	var extra_cache: int = sharding_stacks * max(1, int(sharding_params.get("extra_cache_amount", 1)))
	flags["sharding_cache_used_this_turn"] = true
	player["relic_runtime_flags"] = flags
	_add_class_resource(battle_state, "cache", extra_cache, battle_log, "分库分表额外缓存")

func _cache_from_damage_taken(battle_state: Dictionary, effect_params: Dictionary) -> int:
	if not bool(effect_params.get("from_damage_taken_this_turn", false)):
		return 0
	var player := _player(battle_state)
	var damage_taken := int(player.get("damage_taken_this_turn", 0))
	if damage_taken <= 0:
		return 0
	var divisor: int = max(1, int(effect_params.get("damage_taken_divisor", 1)))
	return int(floor(float(damage_taken) / float(divisor)))

func _service_degrade(battle_state: Dictionary, run_state: Dictionary, params: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	var services: int = _service_count(player)
	var reduction: int = max(0, int(params.get("amount", 0)))
	var reduced_total: int = 0
	for enemy in _alive_enemies(battle_state):
		var intent: Dictionary = enemy.get("intent", {})
		var intent_type := String(intent.get("intent_type", ""))
		if not ["attack", "multi_attack"].has(intent_type):
			continue
		var before_amount: int = int(intent.get("amount", 0))
		var after_amount: int = max(0, before_amount - reduction)
		if after_amount == before_amount:
			continue
		intent["amount"] = after_amount
		enemy["intent"] = intent
		var hits: int = max(1, int(intent.get("hits", 1))) if intent_type == "multi_attack" else 1
		reduced_total += (before_amount - after_amount) * hits
		battle_log.append("%s 服务降级，%s 意图 -%d" % [enemy.get("name", "敌人"), intent_type, before_amount - after_amount])
	if reduction > 0 and reduced_total <= 0:
		battle_log.append("服务降级：本回合没有攻击意图可降低")
	var block_amount: int = max(0, int(params.get("block_amount", 0))) + services * max(0, int(params.get("block_per_service", 0)))
	if block_amount > 0:
		_gain_block(battle_state, run_state, block_amount, battle_log)
	var cache_gain: int = max(0, int(params.get("cache_if_service", 0))) if services > 0 else 0
	if cache_gain > 0:
		_add_cache(battle_state, cache_gain, {}, battle_log)
	if services > 0:
		battle_log.append("服务降级保住 %d 个服务" % services)

func _circuit_breaker(battle_state: Dictionary, run_state: Dictionary, params: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	var services: int = _service_count(player)
	var block_amount: int = max(0, int(params.get("amount", 0)))
	if services > 0:
		block_amount += services * max(0, int(params.get("service_block_amount", 0)))
	var heavy_threshold: int = max(0, int(params.get("heavy_attack_threshold", 0)))
	var heavy_block_amount: int = max(0, int(params.get("heavy_block_amount", 0)))
	if heavy_threshold > 0 and heavy_block_amount > 0 and _incoming_attack_total(battle_state) >= heavy_threshold:
		block_amount += heavy_block_amount
		battle_log.append("熔断保护命中高压攻击")
	if block_amount > 0:
		_gain_block(battle_state, run_state, block_amount, battle_log)
	var cache_gain: int = services * max(0, int(params.get("service_cache_amount", 0)))
	if cache_gain > 0:
		_add_cache(battle_state, cache_gain, {}, battle_log)

func _incoming_attack_total(battle_state: Dictionary) -> int:
	var total: int = 0
	for enemy in _alive_enemies(battle_state):
		var intent: Dictionary = enemy.get("intent", {})
		total += _enemy_intent_attack_amount(intent)
	return total

func _add_compute_complexity(battle_state: Dictionary, amount: int, battle_log: Array) -> void:
	var params: Dictionary = config_service.get_def("statuses", "complexity").get("params", {})
	var gain_per_compute: int = int(params.get("compute_complexity_gain", 0))
	var complexity_gain: int = int(max(0, amount)) * int(max(0, gain_per_compute))
	if complexity_gain > 0:
		_add_class_resource(battle_state, "complexity", complexity_gain, battle_log, "复杂度")

func _add_class_resource(battle_state: Dictionary, key: String, amount: int, battle_log: Array, label: String) -> void:
	var player := _player(battle_state)
	var resources: Dictionary = player.get("class_resource_state", {})
	resources[key] = max(0, int(resources.get(key, 0)) + amount)
	player["class_resource_state"] = resources
	if amount != 0:
		battle_log.append("%s %+d" % [label, amount])

func _add_component(battle_state: Dictionary, run_state: Dictionary, amount: int, params: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	if bool(params.get("requires_existing_component", false)) and _component_count(player) <= 0:
		battle_log.append("没有组件可复用")
		return
	_add_class_resource(battle_state, "components", amount, battle_log, "组件")
	_apply_component_relics(battle_state, run_state, battle_log)
	if amount > 0 and bool(params.get("draw_if_success", false)):
		_draw_cards(battle_state, int(params.get("draw_amount", 1)), battle_log)

func _component_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("components", 0)), int(statuses.get("component", 0)))

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
	if status_id == "requirement_change" and relics.has("relic_pm_meeting_room_claim") and not flags.get("meeting_room_claim_used_this_turn", false):
		flags["meeting_room_claim_used_this_turn"] = true
		var statuses: Dictionary = enemy.get("status_list", {})
		statuses["requirement_change"] = int(statuses.get("requirement_change", 0)) + 1
		enemy["status_list"] = statuses
		_sync_status_resource(battle_state, status_id, 1, battle_log, run_state)
		battle_log.append("会议室占用权追加 1 层需求变更")
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

func _apply_compute_relics(battle_state: Dictionary, run_state: Dictionary, battle_log: Array) -> void:
	var player := _player(battle_state)
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	if run_state.get("owned_relic_ids", []).has("relic_gpu_training_card") and not flags.get("gpu_training_card_used", false):
		flags["gpu_training_card_used"] = true
		_add_class_resource(battle_state, "compute", 1, battle_log, "GPU训练卡追加算力")
		_add_compute_complexity(battle_state, 1, battle_log)
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
