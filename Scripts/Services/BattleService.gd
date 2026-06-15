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
		},
		"enemies": enemies,
		"phase": "player",
		"log": ["遭遇：%s" % encounter.get("id", "")],
	}
	_apply_battle_start_relics(run_state)
	_roll_enemy_intents()
	effect_executor.execute([{ "effect_type": "draw_cards", "target_type": "self", "params": { "amount": 5 } }], battle_state, run_state, 0, battle_state["log"])
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
	var cost := _actual_cost(card)
	return int(player.get("current_energy", 0)) >= cost

func play_card(run_state: Dictionary, hand_index: int, target_index := 0) -> void:
	if not can_play_card(hand_index):
		battle_state["log"].append("精力不足或牌不可用")
		return
	var player: Dictionary = battle_state.get("player", {})
	var hand: Array = player.get("hand", [])
	var card_id := String(hand[hand_index])
	var card: Dictionary = content_resolver.card_def(card_id)
	var cost := _actual_cost(card)
	player["current_energy"] = int(player.get("current_energy", 0)) - cost
	hand.remove_at(hand_index)
	player["cards_played_this_turn"] = int(player.get("cards_played_this_turn", 0)) + 1
	battle_state["log"].append("打出：%s" % card.get("name", card_id))
	var entries: Array = content_resolver.effect_entries(card.get("effect_group_id", ""))
	effect_executor.execute(entries, battle_state, run_state, target_index, battle_state["log"])
	_apply_card_relics(run_state, card)
	player["discard_pile"].append(card_id)
	_check_victory(run_state)

func _actual_cost(card: Dictionary) -> int:
	var cost: int = int(card.get("cost", 1))
	if cost < 0:
		return int(battle_state.get("player", {}).get("current_energy", 0))
	return cost

func _apply_card_relics(run_state: Dictionary, card: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var flags: Dictionary = player.get("relic_runtime_flags", {})
	var relics: Array = run_state.get("owned_relic_ids", [])
	if relics.has("relic_frontend_design_link") and int(player.get("cards_played_this_turn", 0)) == 3:
		player["class_resource_state"]["style_layers"] = int(player["class_resource_state"].get("style_layers", 0)) + 1
	if relics.has("relic_cold_brew_bucket") and int(card.get("cost", 1)) == 0 and not flags.get("cold_brew_used", false):
		player["current_energy"] = int(player.get("current_energy", 0)) + 1
		flags["cold_brew_used"] = true
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
				_enemy_attack(player, enemy, int(intent.get("amount", 0)))
			"block":
				enemy["current_block"] = int(enemy.get("current_block", 0)) + int(intent.get("amount", 0))
				battle_state["log"].append("%s 获得防线" % enemy.get("name", "敌人"))
			"debuff":
				var pstatus: Dictionary = player.get("status_list", {})
				pstatus[String(intent.get("status_id", "anxiety"))] = int(pstatus.get(String(intent.get("status_id", "anxiety")), 0)) + int(intent.get("amount", 1))
				player["status_list"] = pstatus
				battle_state["log"].append("%s 施加负面状态" % enemy.get("name", "敌人"))
	if int(player.get("current_spirit", 0)) <= 0:
		battle_state["phase"] = "defeat"
		run_state["player_state"]["current_spirit"] = 0

func _enemy_attack(player: Dictionary, enemy: Dictionary, amount: int) -> void:
	var block := int(player.get("current_block", 0))
	var blocked := int(min(block, amount))
	player["current_block"] = block - blocked
	var damage := int(amount - blocked)
	player["current_spirit"] = max(0, int(player.get("current_spirit", 0)) - damage)
	player["damage_taken_this_turn"] = int(player.get("damage_taken_this_turn", 0)) + damage
	battle_state["log"].append("%s 造成 %d 压力" % [enemy.get("name", "敌人"), damage])

func _start_player_turn(run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	player["turn_number"] = int(player.get("turn_number", 1)) + 1
	player["cards_played_this_turn"] = 0
	player["damage_taken_this_turn"] = 0
	player["current_block"] = 0
	player["current_energy"] = int(player.get("base_energy", 3))
	_roll_enemy_intents()
	effect_executor.execute([{ "effect_type": "draw_cards", "target_type": "self", "params": { "amount": 5 } }], battle_state, run_state, 0, battle_state["log"])
	battle_state["phase"] = "player"

func _check_victory(run_state: Dictionary) -> void:
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) > 0:
			return
	battle_state["phase"] = "victory"
	run_state["player_state"]["current_spirit"] = int(battle_state.get("player", {}).get("current_spirit", 1))
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
	}

func _maybe_relic_reward(run_state: Dictionary) -> Array:
	if battle_state.get("node_type", "") != "elite_battle" and battle_state.get("node_type", "") != "boss":
		return []
	var relics: Array = content_resolver.relics_for_run_class(run_state.get("selected_class_id", ""))
	relics.shuffle()
	return relics.slice(0, min(2, relics.size())).map(func(relic): return relic.get("id", ""))
