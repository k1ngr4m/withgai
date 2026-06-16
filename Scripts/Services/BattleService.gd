class_name BattleService
extends RefCounted

const PLAYER_POSITIVE_STATUS_IDS := [
	"service_online",
	"cache",
	"component",
	"style_layer",
	"vue_suite",
	"case_mark",
	"diff",
	"compute",
	"complexity",
	"requirement_change",
	"priority",
	"scope_spread",
	"performance",
]
const PLAYER_TURN_END_DECAY_STATUS_IDS := ["weak", "vulnerable"]
const ENEMY_ACTION_END_DECAY_STATUS_IDS := ["weak", "vulnerable"]

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
		enemies.append(_build_enemy(String(enemy_id)))
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
	_persist_battle(run_state)
	return battle_state

func restore_battle(run_state: Dictionary) -> bool:
	var saved_battle: Dictionary = run_state.get("active_battle_state", {})
	if saved_battle.is_empty():
		return false
	battle_state = saved_battle
	run_state["active_battle_state"] = battle_state
	return true

func _persist_battle(run_state: Dictionary) -> void:
	if battle_state.is_empty() or ["victory", "defeat"].has(String(battle_state.get("phase", ""))):
		run_state["active_battle_state"] = {}
	else:
		run_state["active_battle_state"] = battle_state

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

func _build_enemy(enemy_id: String) -> Dictionary:
	var def: Dictionary = content_resolver.enemy_def(enemy_id)
	if def.is_empty():
		return {}
	return {
		"enemy_def_id": enemy_id,
		"name": def.get("name", enemy_id),
		"max_hp": int(def.get("base_hp", 30)),
		"current_hp": int(def.get("base_hp", 30)),
		"current_block": 0,
		"phase_index": 0,
		"intent": {},
		"status_list": {},
		"runtime_flags": {},
	}

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
	battle_state["last_play_context"] = {
		"card_id": card_id,
		"cost_paid": cost,
		"printed_cost": int(card.get("cost", 1)),
		"is_x_cost": int(card.get("cost", 1)) < 0,
	}
	var entries: Array = _actual_effect_entries(card)
	effect_executor.execute(entries, battle_state, run_state, target_index, battle_state["log"])
	_check_enemy_phase_triggers(run_state)
	_collect_defeated_enemies(run_state)
	_apply_card_relics(run_state, card)
	player["discard_pile"].append(card_id)
	_check_victory(run_state)
	_persist_battle(run_state)

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
	return ["single_enemy", "selected"].has(target_type)

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
		_persist_battle(run_state)
		return
	battle_state["phase"] = "enemy"
	_enemy_turn(run_state)
	if battle_state.get("phase", "") == "defeat":
		_persist_battle(run_state)
		return
	_start_player_turn(run_state)
	_persist_battle(run_state)

func _enemy_turn(run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var acting_enemies: Array = battle_state.get("enemies", []).duplicate()
	for enemy in acting_enemies:
		if int(enemy.get("current_hp", 0)) <= 0:
			continue
		var statuses: Dictionary = enemy.get("status_list", {})
		if int(statuses.get("bug", 0)) > 0:
			statuses["bug"] = int(statuses.get("bug", 0)) - 1
			enemy["status_list"] = statuses
			battle_state["log"].append("%s 的行动被 Bug 卡住" % enemy.get("name", "敌人"))
			continue
		_apply_requirement_change_before_action(enemy)
		var intent: Dictionary = enemy.get("intent", {})
		match intent.get("intent_type", ""):
			"attack":
				_enemy_attack(player, enemy, int(intent.get("amount", 0)), run_state)
			"multi_attack":
				_enemy_multi_attack(player, enemy, intent, run_state)
			"block":
				enemy["current_block"] = int(enemy.get("current_block", 0)) + int(intent.get("amount", 0))
				battle_state["log"].append("%s 获得防线" % enemy.get("name", "敌人"))
			"debuff":
				var pstatus: Dictionary = player.get("status_list", {})
				pstatus[String(intent.get("status_id", "anxiety"))] = int(pstatus.get(String(intent.get("status_id", "anxiety")), 0)) + int(intent.get("amount", 1))
				player["status_list"] = pstatus
				battle_state["log"].append("%s 施加负面状态" % enemy.get("name", "敌人"))
			"pollute":
				_pollute_player(player, String(intent.get("card_id", "")), String(intent.get("destination", "discard")), int(intent.get("amount", 1)), String(enemy.get("name", "敌人")))
			"spawn":
				_spawn_enemy(String(intent.get("enemy_id", "")), int(intent.get("amount", 1)), int(intent.get("max_allies", 0)), String(enemy.get("name", "敌人")))
			"cleanse_player":
				_cleanse_player_boons(player, int(intent.get("amount", 1)), String(enemy.get("name", "敌人")))
				if not String(intent.get("card_id", "")).is_empty():
					_pollute_player(player, String(intent.get("card_id", "")), String(intent.get("destination", "discard")), 1, String(enemy.get("name", "敌人")))
			"phase_shift":
				_phase_shift_enemy(enemy, int(intent.get("amount", 0)))
		_tick_enemy_action_statuses(enemy)
		_collect_defeated_enemies(run_state)
	if int(player.get("current_spirit", 0)) <= 0:
		battle_state["phase"] = "defeat"
		run_state["player_state"]["current_spirit"] = 0
		run_state["active_battle_state"] = {}
	else:
		_check_victory(run_state)

func _enemy_multi_attack(player: Dictionary, enemy: Dictionary, intent: Dictionary, run_state: Dictionary) -> void:
	var hits: int = max(1, int(intent.get("hits", 2)))
	var amount := int(intent.get("amount", 0))
	battle_state["log"].append("%s 发起 %d 段压迫" % [enemy.get("name", "敌人"), hits])
	for i in range(hits):
		if int(player.get("current_spirit", 0)) <= 0:
			break
		_enemy_attack(player, enemy, amount, run_state)

func _enemy_attack(player: Dictionary, enemy: Dictionary, amount: int, run_state: Dictionary) -> void:
	var final_amount := amount
	var enemy_statuses: Dictionary = enemy.get("status_list", {})
	if int(enemy_statuses.get("weak", 0)) > 0:
		final_amount = int(floor(final_amount * 0.75))
	var player_statuses: Dictionary = player.get("status_list", {})
	if int(player_statuses.get("vulnerable", 0)) > 0:
		final_amount = int(ceil(final_amount * 1.5))
	var block := int(player.get("current_block", 0))
	var blocked := int(min(block, final_amount))
	player["current_block"] = block - blocked
	var damage := int(final_amount - blocked)
	player["current_spirit"] = max(0, int(player.get("current_spirit", 0)) - damage)
	player["damage_taken_this_turn"] = int(player.get("damage_taken_this_turn", 0)) + damage
	battle_state["log"].append("%s 造成 %d 压力" % [enemy.get("name", "敌人"), damage])
	if damage > 0:
		_apply_damage_taken_relics(player, run_state, damage)

func _pollute_player(player: Dictionary, card_id: String, destination: String, amount: int, source_name: String) -> void:
	if card_id.is_empty() or content_resolver.card_def(card_id).is_empty():
		battle_state["log"].append("%s 的污染牌配置缺失" % source_name)
		return
	var pile_name := "discard_pile"
	if destination == "hand":
		pile_name = "hand"
	elif destination == "draw":
		pile_name = "draw_pile"
	var pile: Array = player.get(pile_name, [])
	for i in range(max(1, amount)):
		pile.append(card_id)
	player[pile_name] = pile
	battle_state["log"].append("%s 塞入污染牌 %s x%d" % [source_name, content_resolver.card_def(card_id).get("name", card_id), max(1, amount)])

func _spawn_enemy(enemy_id: String, amount: int, max_allies: int, source_name: String) -> void:
	if enemy_id.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(max(1, amount)):
		if max_allies > 0 and _alive_enemy_count() >= max_allies:
			battle_state["log"].append("%s 呼叫增援，但会议室已经坐满" % source_name)
			return
		var spawned := _build_enemy(enemy_id)
		if spawned.is_empty():
			battle_state["log"].append("%s 的增援配置缺失" % source_name)
			return
		var intents: Array = content_resolver.intent_entries_for_enemy(enemy_id)
		if not intents.is_empty():
			spawned["intent"] = content_resolver.weighted_pick(intents, rng).duplicate(true)
		battle_state["enemies"].append(spawned)
		battle_state["log"].append("%s 召唤增援：%s" % [source_name, spawned.get("name", enemy_id)])

func _alive_enemy_count() -> int:
	var count := 0
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) > 0:
			count += 1
	return count

func _cleanse_player_boons(player: Dictionary, amount: int, source_name: String) -> void:
	var statuses: Dictionary = player.get("status_list", {})
	var removed_statuses := 0
	for status_id in PLAYER_POSITIVE_STATUS_IDS:
		if statuses.has(status_id):
			statuses.erase(status_id)
			removed_statuses += 1
	player["status_list"] = statuses
	var resources: Dictionary = player.get("class_resource_state", {})
	var cleanse_amount: int = max(1, amount)
	var reduced_resources := 0
	for key in resources.keys():
		if int(resources.get(key, 0)) <= 0:
			continue
		resources[key] = max(0, int(resources.get(key, 0)) - cleanse_amount)
		reduced_resources += 1
	player["class_resource_state"] = resources
	battle_state["log"].append("%s 清理玩家增益：状态 %d 个，资源 %d 项" % [source_name, removed_statuses, reduced_resources])

func _phase_shift_enemy(enemy: Dictionary, amount: int) -> void:
	enemy["phase_index"] = int(enemy.get("phase_index", 0)) + 1
	if amount > 0:
		enemy["current_block"] = int(enemy.get("current_block", 0)) + amount
	battle_state["log"].append("%s 切换阶段" % enemy.get("name", "敌人"))

func _check_enemy_phase_triggers(run_state: Dictionary) -> void:
	for enemy in battle_state.get("enemies", []):
		if int(enemy.get("current_hp", 0)) <= 0:
			continue
		var entries: Array = content_resolver.phase_entries_for_enemy(String(enemy.get("enemy_def_id", "")))
		if entries.is_empty():
			continue
		var max_hp: int = max(1, int(enemy.get("max_hp", 1)))
		var hp_pct: float = float(enemy.get("current_hp", 0)) / float(max_hp)
		for phase in entries:
			var threshold_pct: float = float(phase.get("threshold_pct", 0.0))
			if threshold_pct <= 0.0 or hp_pct > threshold_pct:
				continue
			var phase_id := String(phase.get("id", "phase_%s" % str(threshold_pct)))
			var flags: Dictionary = enemy.get("runtime_flags", {})
			var triggered: Array = flags.get("triggered_phases", [])
			if triggered.has(phase_id):
				continue
			triggered.append(phase_id)
			flags["triggered_phases"] = triggered
			enemy["runtime_flags"] = flags
			enemy["phase_index"] = max(int(enemy.get("phase_index", 0)), int(phase.get("order", 0)))
			battle_state["log"].append("%s 进入阶段：%s" % [enemy.get("name", "敌人"), phase.get("name", phase_id)])
			_execute_phase_actions(enemy, phase.get("actions", []), run_state)

func _execute_phase_actions(enemy: Dictionary, actions: Array, _run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	for action in actions:
		var action_type := String(action.get("action_type", ""))
		match action_type:
			"block":
				enemy["current_block"] = int(enemy.get("current_block", 0)) + int(action.get("amount", 0))
				battle_state["log"].append("%s 阶段防线 +%d" % [enemy.get("name", "敌人"), int(action.get("amount", 0))])
			"pollute":
				_pollute_player(player, String(action.get("card_id", "")), String(action.get("destination", "discard")), int(action.get("amount", 1)), String(enemy.get("name", "敌人")))
			"spawn":
				_spawn_enemy(String(action.get("enemy_id", "")), int(action.get("amount", 1)), int(action.get("max_allies", 0)), String(enemy.get("name", "敌人")))
			"cleanse_player":
				_cleanse_player_boons(player, int(action.get("amount", 1)), String(enemy.get("name", "敌人")))
			"debuff_player":
				_add_player_status(player, String(action.get("status_id", "anxiety")), int(action.get("amount", 1)), String(enemy.get("name", "敌人")))
			"status_self":
				_add_enemy_status(enemy, String(action.get("status_id", "")), int(action.get("amount", 1)))
			"force_intent":
				var next_intent: Dictionary = action.get("intent", {}).duplicate(true)
				if not next_intent.is_empty():
					enemy["intent"] = next_intent
					battle_state["log"].append("%s 重置意图为 %s" % [enemy.get("name", "敌人"), next_intent.get("intent_type", "")])

func _add_player_status(player: Dictionary, status_id: String, amount: int, source_name: String) -> void:
	if status_id.is_empty():
		return
	var statuses: Dictionary = player.get("status_list", {})
	statuses[status_id] = int(statuses.get(status_id, 0)) + max(1, amount)
	player["status_list"] = statuses
	battle_state["log"].append("%s 施加 %s x%d" % [source_name, status_id, max(1, amount)])

func _add_enemy_status(enemy: Dictionary, status_id: String, amount: int) -> void:
	if status_id.is_empty():
		return
	var statuses: Dictionary = enemy.get("status_list", {})
	statuses[status_id] = int(statuses.get(status_id, 0)) + max(1, amount)
	enemy["status_list"] = statuses
	battle_state["log"].append("%s 获得 %s x%d" % [enemy.get("name", "敌人"), status_id, max(1, amount)])

func _apply_requirement_change_before_action(enemy: Dictionary) -> void:
	var statuses: Dictionary = enemy.get("status_list", {})
	var stacks := int(statuses.get("requirement_change", 0))
	if stacks <= 0:
		return
	var intent: Dictionary = enemy.get("intent", {})
	var intent_type := String(intent.get("intent_type", ""))
	if not ["attack", "multi_attack", "block", "debuff"].has(intent_type):
		return
	var params := _status_params("requirement_change")
	var consume: int = int(clamp(int(params.get("consume_per_action", 1)), 1, stacks))
	var reduction: int = int(max(0, int(params.get("intent_amount_reduction", 0)))) * consume
	if reduction <= 0:
		return
	var before_amount: int = int(intent.get("amount", 0))
	intent["amount"] = max(0, before_amount - reduction)
	enemy["intent"] = intent
	statuses["requirement_change"] = max(0, stacks - consume)
	enemy["status_list"] = statuses
	_adjust_player_class_resource("requirement_change_marks", -consume)
	battle_state["log"].append("%s 的需求被改写，%s 意图 -%d" % [enemy.get("name", "敌人"), intent_type, min(before_amount, reduction)])

func _start_player_turn(run_state: Dictionary, first_turn := false) -> void:
	var player: Dictionary = battle_state.get("player", {})
	if not first_turn:
		player["turn_number"] = int(player.get("turn_number", 1)) + 1
	player["cards_played_this_turn"] = 0
	player["damage_taken_this_turn"] = 0
	if not first_turn:
		player["current_block"] = 0
	player["relic_runtime_flags"]["standing_desk_block_used"] = false
	player["relic_runtime_flags"]["meeting_room_claim_used_this_turn"] = false
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
	run_state["active_battle_state"] = {}
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
		statuses["overtime"] = max(0, int(statuses.get("overtime", 0)) - 1)
		battle_state["log"].append("加班造成精神消耗")
	player["status_list"] = statuses
	_apply_complexity_pressure(player)
	var vue_suite_stacks := _vue_suite_count(player)
	if vue_suite_stacks > 0 and effect_executor != null:
		var params: Dictionary = _status_params("vue_suite")
		var component_amount: int = int(max(1, int(params.get("component_amount", 1)))) * vue_suite_stacks
		effect_executor.execute(
			[{ "effect_type": "add_component", "target_type": "self", "params": { "amount": component_amount } }],
			battle_state,
			run_state,
			0,
			battle_state["log"]
		)
		battle_state["log"].append("Vue三件套在回合开始生成组件")
	var resources: Dictionary = player.get("class_resource_state", {})
	var services := _service_online_count(player)
	if services > 0:
		resources["cache"] = int(resources.get("cache", 0)) + services
		player["current_block"] = int(player.get("current_block", 0)) + services * 2
		player["class_resource_state"] = resources
		battle_state["log"].append("服务在线：缓存 +%d，防线 +%d" % [services, services * 2])
	if first_turn and run_state.get("owned_relic_ids", []).has("relic_lumbar_cushion"):
		battle_state["log"].append("护腰靠垫提供开局防线")

func _round_end_triggers(run_state: Dictionary) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var services := _service_online_count(player)
	if services > 0:
		var damage := services * 2
		for enemy in battle_state.get("enemies", []):
			if int(enemy.get("current_hp", 0)) <= 0:
				continue
			enemy["current_hp"] = max(0, int(enemy.get("current_hp", 0)) - damage)
			battle_state["log"].append("服务巡检对 %s 造成 %d 伤害" % [enemy.get("name", "敌人"), damage])
		_check_enemy_phase_triggers(run_state)
		_collect_defeated_enemies(run_state)
	_tick_player_turn_end_statuses(player)

func _service_online_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("services", 0)), int(statuses.get("service_online", 0)))

func _apply_complexity_pressure(player: Dictionary) -> void:
	var params := _status_params("complexity")
	var threshold := int(params.get("pressure_threshold", 0))
	if threshold <= 0:
		return
	var complexity := _complexity_count(player)
	if complexity < threshold:
		return
	var energy_loss := int(params.get("energy_loss", 0))
	var spirit_loss := int(params.get("spirit_loss", 0))
	var log_parts: Array = []
	if energy_loss > 0:
		player["current_energy"] = max(0, int(player.get("current_energy", 0)) - energy_loss)
		log_parts.append("精力 -%d" % energy_loss)
	if spirit_loss > 0:
		player["current_spirit"] = max(0, int(player.get("current_spirit", 0)) - spirit_loss)
		log_parts.append("精神 -%d" % spirit_loss)
	if not log_parts.is_empty():
		battle_state["log"].append("复杂度过高：%s" % "，".join(log_parts))

func _complexity_count(player: Dictionary) -> int:
	var resources: Dictionary = player.get("class_resource_state", {})
	var statuses: Dictionary = player.get("status_list", {})
	return max(int(resources.get("complexity", 0)), int(statuses.get("complexity", 0)))

func _vue_suite_count(player: Dictionary) -> int:
	var statuses: Dictionary = player.get("status_list", {})
	return int(statuses.get("vue_suite", 0))

func _status_params(status_id: String) -> Dictionary:
	if content_resolver == null or content_resolver.config_service == null:
		return {}
	return content_resolver.config_service.get_def("statuses", status_id).get("params", {})

func _adjust_player_class_resource(resource_key: String, amount: int) -> void:
	var player: Dictionary = battle_state.get("player", {})
	var resources: Dictionary = player.get("class_resource_state", {})
	resources[resource_key] = max(0, int(resources.get(resource_key, 0)) + amount)
	player["class_resource_state"] = resources

func _tick_player_turn_end_statuses(player: Dictionary) -> void:
	var statuses: Dictionary = player.get("status_list", {})
	for status_id in PLAYER_TURN_END_DECAY_STATUS_IDS:
		if int(statuses.get(status_id, 0)) > 0:
			statuses[status_id] = max(0, int(statuses.get(status_id, 0)) - 1)
	player["status_list"] = statuses

func _tick_enemy_action_statuses(enemy: Dictionary) -> void:
	var statuses: Dictionary = enemy.get("status_list", {})
	for status_id in ENEMY_ACTION_END_DECAY_STATUS_IDS:
		if int(statuses.get(status_id, 0)) > 0:
			statuses[status_id] = max(0, int(statuses.get(status_id, 0)) - 1)
	enemy["status_list"] = statuses

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
