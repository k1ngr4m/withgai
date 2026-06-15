class_name BattleService
extends RefCounted

var content_resolver
var effect_executor: EffectExecutor
var battle_state: Dictionary = {}

func setup(p_content_resolver, p_effect_executor: EffectExecutor) -> void:
	content_resolver = p_content_resolver
	effect_executor = p_effect_executor

func start_battle(run_state: Dictionary, node: Dictionary) -> Dictionary:
	var encounter := _select_encounter(run_state, node)
	var enemies: Array = []
	for enemy_id in encounter.get("enemy_ids", []):
		var def: Dictionary = content_resolver.enemy_def(enemy_id)
		enemies.append({
			"enemy_def_id": enemy_id,
			"name": def.get("name", enemy_id),
			"max_hp": int(def.get("base_hp", 30)),
			"current_hp": int(def.get("base_hp", 30)),
			"current_block": 0,
			"phase_index": 0,
			"intent": {},
			"status_list": {},
			"runtime_flags": {},
		})
	var deck: Array = run_state.get("deck_state", {}).get("master_deck", []).duplicate(true)
	deck.shuffle()
	battle_state = {
		"encounter_id": encounter.get("id", ""),
		"node_type": node.get("node_type", "normal_battle"),
		"chapter": run_state.get("current_chapter", 1),
		"selected_class_id": run_state.get("selected_class_id", ""),
		"player": {
			"max_spirit": int(run_state.get("player_state", {}).get("max_spirit", 72)),
			"current_spirit": int(run_state.get("player_state", {}).get("current_spirit", 72)),
			"current_energy": int(run_state.get("player_state", {}).get("base_energy", 3)),
			"base_energy": int(run_state.get("player_state", {}).get("base_energy", 3)),
			"current_block": 0,
			"draw_pile": deck,
			"hand": [],
			"discard_pile": [],
			"exhaust_pile": [],
			"status_list": {},
			"relic_runtime_flags": {},
			"class_resource_state": _initial_class_resources(run_state.get("selected_class_id", "")),
			"cards_played_this_turn": 0,
			"damage_taken_this_turn": 0,
			"turn_number": 1,
			"opening_draw_bonus": int(run_state.get("player_state", {}).get("opening_draw_bonus", 0)),
			"opening_block_bonus": int(run_state.get("player_state", {}).get("opening_block_bonus", 0)),
		},
		"enemies": enemies,
		"phase": "player",
		"selected_target_index": 0,
		"upgraded_card_ids": run_state.get("deck_state", {}).get("upgraded_cards", []).duplicate(true),
		"runtime_flags": {},
		"log": ["遭遇：%s" % encounter.get("id", "")],
	}
	_apply_battle_start_relics(run_state)
	_start_player_turn(run_state, true)
	return battle_state

func _initial_class_resources(class_id: String) -> Dictionary:
	match class_id:
		"backend":
			return { "services": 0, "cache": 0 }
		"frontend":
			return { "components": 0, "style_layers": 0 }
		"tester":
			return { "bugs": 0, "cases": 0, "diff_tags": 0 }
		"algorithm":
			return { "compute": 0, "complexity": 0 }
		"product_manager":
			return { "priority_targets": 0, "requirement_change_marks": 0 }
		_:
			return {}

func _select_encounter(run_state: Dictionary, node: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run_state.get("rng_seed", 1)) + int(run_state.get("current_floor", 1)) * 31
	var rows: Array = content_resolver.encounters_for_node(
		int(run_state.get("current_chapter", 1)),
		node.get("node_type", "normal_battle"),
		int(node.get("floor", run_state.get("current_floor", 1)))
	)
	return content_resolver.weighted_pick(rows, rng)

func _apply_battle_start_relics(run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if relics.has("relic_backend_gray_release"):
		player["class_resource_state"]["cache"] = int(player["class_resource_state"].get("cache", 0)) + 1
	if relics.has("relic_lumbar_cushion"):
		player["current_block"] = int(player.get("current_block", 0)) + 4
	if relics.has("relic_hair_shampoo"):
		player["max_spirit"] = int(player.get("max_spirit", 72)) + 6
		player["current_spirit"] = int(player.get("current_spirit", 72)) + 6
	if int(player.get("opening_block_bonus", 0)) > 0:
		player["current_block"] = int(player.get("current_block", 0)) + int(player.get("opening_block_bonus", 0))

func _roll_enemy_intents() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) <= 0:
			continue
		var intents: Array = content_resolver.intent_entries_for_enemy(enemy.get("enemy_def_id", ""))
		enemy["intent"] = content_resolver.weighted_pick(intents, rng).duplicate(true)

func can_play_card(hand_index: int) -> bool:
	var player: Dictionary = battle_state.get("player", {})
	if battle_state.get("phase", "") != "player":
		return false
	var hand: Array = player.get("hand", [])
	if hand_index < 0 or hand_index >= hand.size():
		return false
	var card: Dictionary = content_resolver.card_def(hand[hand_index])
	var cost := _actual_cost(card, hand[hand_index])
	return int(player.get("current_energy", 0)) >= cost

func play_card(run_state: Dictionary, hand_index: int, target_index := 0) -> void:
	if not can_play_card(hand_index):
		battle_state["log"].append("精力不足或牌不可用")
		return
	var player: Dictionary = battle_state.get("player", {})
	var hand: Array = player.get("hand", [])
	var card_id := String(hand[hand_index])
	var card: Dictionary = content_resolver.card_def(card_id)
	var cost := _actual_cost(card, card_id)
	player["current_energy"] = int(player.get("current_energy", 0)) - cost
	hand.remove_at(hand_index)
	player["cards_played_this_turn"] = int(player.get("cards_played_this_turn", 0)) + 1
	var upgraded := _is_card_upgraded(card_id)
	battle_state["log"].append("打出：%s%s" % [card.get("name", card_id), "+" if upgraded else ""])
	var entries: Array = _actual_effect_entries(card)
	effect_executor.execute(entries, battle_state, run_state, target_index, battle_state["log"])
	_collect_defeated_enemies(run_state)
	_apply_card_relics(run_state, card)
	player["discard_pile"].append(card_id)
	_check_victory(run_state)

func select_target(target_index: int) -> void:
	var enemies: Array = battle_state.get("enemies", [])
	if enemies.is_empty():
		battle_state["selected_target_index"] = 0
		return
	target_index = clamp(target_index, 0, enemies.size() - 1)
	if int(enemies[target_index].get("current_hp", 0)) <= 0:
		for i in range(enemies.size()):
			if int(enemies[i].get("current_hp", 0)) > 0:
				target_index = i
				break
	battle_state["selected_target_index"] = target_index

func selected_target_index() -> int:
	return int(battle_state.get("selected_target_index", 0))

func card_needs_target(card_id: String) -> bool:
	var card: Dictionary = content_resolver.card_def(card_id)
	var target_type := String(card.get("target_type", "self"))
	return ["single_enemy", "selected", "all_enemies", "random_enemy", "lowest_hp_enemy", "highest_priority_enemy"].has(target_type)

func _actual_cost(card: Dictionary, card_id := "") -> int:
	var cost: int = int(card.get("cost", 1))
	if cost < 0:
		return int(battle_state.get("player", {}).get("current_energy", 0))
	if _is_card_upgraded(card_id):
		return max(0, cost - 1)
	return cost

func _actual_effect_entries(card: Dictionary) -> Array:
	var entries: Array = content_resolver.effect_entries(card.get("effect_group_id", ""))
	if not _is_card_upgraded(card.get("id", "")):
		return entries
	var upgraded_entries: Array = []
	for entry in entries:
		var next_entry: Dictionary = entry.duplicate(true)
		var params: Dictionary = next_entry.get("params", {}).duplicate(true)
		var effect_type := String(next_entry.get("effect_type", ""))
		if params.has("amount") and ["deal_damage", "gain_block", "add_cache", "add_component", "add_style_layer", "add_compute", "add_case", "inject_bug"].has(effect_type):
			params["amount"] = int(params.get("amount", 0)) + 2
		next_entry["params"] = params
		upgraded_entries.append(next_entry)
	return upgraded_entries

func _is_card_upgraded(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	return battle_state.get("upgraded_card_ids", []).has(card_id)

func _apply_card_relics(run_state: Dictionary, card: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if relics.has("relic_frontend_design_link") and int(player.get("cards_played_this_turn", 0)) == 3:
		player["class_resource_state"]["style_layers"] = int(player["class_resource_state"].get("style_layers", 0)) + 1
	if relics.has("relic_cold_brew_bucket") and int(card.get("cost", 1)) == 0 and not flags.get("cold_brew_used", false):
		player["current_energy"] = int(player.get("current_energy", 0)) + 1
		flags["cold_brew_used"] = true
	if relics.has("relic_algorithm_local_cluster") and int(card.get("cost", 1)) < 0 and not flags.get("local_cluster_x_used", false):
		player["current_energy"] = int(player.get("current_energy", 0)) + 1
		flags["local_cluster_x_used"] = true
	if relics.has("relic_backend_gray_release") and card.get("id", "") == "card_backend_publish_script" and not flags.get("gray_release_draw", false):
		effect_executor.execute([{ "effect_type": "draw_cards", "target_type": "self", "params": { "amount": 1 } }], battle_state, run_state, 0, battle_state["log"])
		flags["gray_release_draw"] = true
	player["relic_runtime_flags"] = flags

func end_turn(run_state: Dictionary) -> void:
	if battle_state.get("phase", "") != "player":
		return
	var player: Dictionary = battle_state.get("player", {})
	player["discard_pile"].append_array(player.get("hand", []))
	player["hand"] = []
	_round_end_triggers(run_state)
	_check_victory(run_state)
	if battle_state.get("phase", "") == "victory":
		return
	battle_state["phase"] = "enemy"
	_enemy_turn(run_state)
	if battle_state.get("phase", "") == "defeat":
		return
	_start_player_turn(run_state)

func _enemy_turn(run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) <= 0:
			continue
		var statuses: Dictionary = enemy.get("status_list", {})
		if int(statuses.get("bug", 0)) > 0:
			statuses["bug"] = int(statuses.get("bug", 0)) - 1
			enemy["status_list"] = statuses
			battle_state["log"].append("%s 的行动被 Bug 卡住" % enemy.get("name", "敌人"))
			continue
		var intent: Dictionary = enemy.get("intent", {})
		match intent.get("intent_type", ""):
			"attack":
				_enemy_attack(player, enemy, int(intent.get("amount", 0)), run_state)
			"block":
				enemy["current_block"] = int(enemy.get("current_block", 0)) + int(intent.get("amount", 0))
				battle_state["log"].append("%s 获得防线" % enemy.get("name", "敌人"))
			"debuff":
				var pstatus: Dictionary = player.get("status_list", {})
				pstatus[String(intent.get("status_id", "anxiety"))] = int(pstatus.get(String(intent.get("status_id", "anxiety")), 0)) + int(intent.get("amount", 1))
				player["status_list"] = pstatus
				battle_state["log"].append("%s 施加负面状态" % enemy.get("name", "敌人"))
		_collect_defeated_enemies(run_state)
	if int(player.get("current_spirit", 0)) <= 0:
		battle_state["phase"] = "defeat"
		run_state["player_state"]["current_spirit"] = 0
	else:
		_check_victory(run_state)

func _enemy_attack(player: Dictionary, enemy: Dictionary, amount: int, run_state: Dictionary) -> void:
	var block := int(player.get("current_block", 0))
	var blocked := int(min(block, amount))
	player["current_block"] = block - blocked
	var damage := int(amount - blocked)
	player["current_spirit"] = max(0, int(player.get("current_spirit", 0)) - damage)
	player["damage_taken_this_turn"] = int(player.get("damage_taken_this_turn", 0)) + damage
	battle_state["log"].append("%s 造成 %d 压力" % [enemy.get("name", "敌人"), damage])
	if damage > 0:
		_apply_damage_taken_relics(player, run_state, damage)

func _start_player_turn(run_state: Dictionary, first_turn := false) -> void:
	var player: Dictionary = battle_state.get("player", {})
	if not first_turn:
		player["turn_number"] = int(player.get("turn_number", 1)) + 1
	player["cards_played_this_turn"] = 0
	player["damage_taken_this_turn"] = 0
	if not first_turn:
		player["current_block"] = 0
	player["relic_runtime_flags"]["standing_desk_block_used"] = false
	player["current_energy"] = int(player.get("base_energy", 3))
	_round_start_triggers(run_state, first_turn)
	_roll_enemy_intents()
	var draw_amount := 5
	if first_turn:
		draw_amount += int(player.get("opening_draw_bonus", 0))
		if run_state.get("owned_relic_ids", []).has("relic_blue_light_glasses"):
			draw_amount += 1
	effect_executor.execute([{ "effect_type": "draw_cards", "target_type": "self", "params": { "amount": draw_amount } }], battle_state, run_state, 0, battle_state["log"])
	battle_state["phase"] = "player"

func _check_victory(run_state: Dictionary) -> void:
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) > 0:
			return
	var runtime_flags: Dictionary = battle_state.get("runtime_flags", {})
	if runtime_flags.get("victory_recorded", false):
		return
	runtime_flags["victory_recorded"] = true
	battle_state["runtime_flags"] = runtime_flags
	battle_state["phase"] = "victory"
	run_state["player_state"]["current_spirit"] = int(battle_state.get("player", {}).get("current_spirit", 1))
	var counters: Dictionary = run_state.get("run_counters", {})
	counters["battles_won"] = int(counters.get("battles_won", 0)) + 1
	run_state["run_counters"] = counters
	run_state["pending_reward_state"] = generate_reward(run_state)

func generate_reward(run_state: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run_state.get("rng_seed", 1)) + int(run_state.get("visited_node_ids", []).size()) * 53 + 7
	var pool: Array = content_resolver.cards_for_run_class(run_state.get("selected_class_id", ""), true)
	pool.shuffle()
	var candidates: Array = []
	for card in pool:
		if candidates.size() >= 3:
			break
		candidates.append(card.get("id", ""))
	var currency := rng.randi_range(18, 35)
	if battle_state.get("node_type", "") == "elite_battle":
		currency += 20
	return {
		"reward_type": "battle",
		"candidate_card_ids": candidates,
		"candidate_relic_ids": _maybe_relic_reward(run_state),
		"currency_amount": currency,
		"special_rewards": [],
		"source_encounter_id": battle_state.get("encounter_id", ""),
		"source_node_type": battle_state.get("node_type", ""),
	}

func _maybe_relic_reward(run_state: Dictionary) -> Array:
	if battle_state.get("node_type", "") != "elite_battle" and battle_state.get("node_type", "") != "boss":
		return []
	var relics: Array = content_resolver.relics_for_run_class(run_state.get("selected_class_id", ""))
	relics.shuffle()
	return relics.slice(0, min(2, relics.size())).map(func(relic): return relic.get("id", ""))

func _round_start_triggers(run_state: Dictionary, first_turn: bool) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var statuses: Dictionary = player.get("status_list", {})
	if int(statuses.get("anxiety", 0)) > 0:
		player["current_energy"] = max(0, int(player.get("current_energy", 0)) - 1)
		statuses["anxiety"] = int(statuses.get("anxiety", 0)) - 1
		battle_state["log"].append("焦虑让本回合精力 -1")
	if int(statuses.get("overtime", 0)) > 0:
		player["current_spirit"] = max(0, int(player.get("current_spirit", 0)) - int(statuses.get("overtime", 0)))
		battle_state["log"].append("加班造成精神消耗")
	player["status_list"] = statuses
	var resources: Dictionary = player.get("class_resource_state", {})
	var services := int(resources.get("services", 0))
	if services > 0:
		resources["cache"] = int(resources.get("cache", 0)) + services
		player["current_block"] = int(player.get("current_block", 0)) + services * 2
		player["class_resource_state"] = resources
		battle_state["log"].append("服务在线：缓存 +%d，防线 +%d" % [services, services * 2])
	if first_turn and run_state.get("owned_relic_ids", []).has("relic_lumbar_cushion"):
		battle_state["log"].append("护腰靠垫提供开局防线")

func _round_end_triggers(run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var resources: Dictionary = player.get("class_resource_state", {})
	var services := int(resources.get("services", 0))
	if services <= 0:
		return
	var damage := services * 2
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) <= 0:
			continue
		enemy["current_hp"] = max(0, int(enemy.get("current_hp", 0)) - damage)
		battle_state["log"].append("服务巡检对 %s 造成 %d 伤害" % [enemy.get("name", "敌人"), damage])
	_collect_defeated_enemies(run_state)

func _collect_defeated_enemies(run_state: Dictionary) -> void:
	var counters: Dictionary = run_state.get("run_counters", {})
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) > 0:
			continue
		var flags: Dictionary = enemy.get("runtime_flags", {})
		if flags.get("defeat_recorded", false):
			continue
		flags["defeat_recorded"] = true
		enemy["runtime_flags"] = flags
		counters["enemies_defeated"] = int(counters.get("enemies_defeated", 0)) + 1
		battle_state["log"].append("%s 被处理掉了" % enemy.get("name", "敌人"))
	run_state["run_counters"] = counters

func _apply_damage_taken_relics(player: Dictionary, run_state: Dictionary, damage: int) -> void:
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if relics.has("relic_read_replica") and not flags.get("read_replica_used", false):
		flags["read_replica_used"] = true
		var resources: Dictionary = player.get("class_resource_state", {})
		resources["cache"] = int(resources.get("cache", 0)) + max(1, int(ceil(damage / 4.0)))
		player["class_resource_state"] = resources
		battle_state["log"].append("只读从库快照返还缓存")
	player["relic_runtime_flags"] = flags
