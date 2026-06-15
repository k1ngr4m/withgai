class_name RewardService
extends RefCounted

const CARD_COST := 45
const RELIC_COST := 85
const REMOVE_COST := 75

var content_resolver
var map_service: MapService
var meta_service: MetaProgressionService

func setup(p_content_resolver, p_map_service: MapService, p_meta_service: MetaProgressionService) -> void:
	content_resolver = p_content_resolver
	map_service = p_map_service
	meta_service = p_meta_service

func accept_battle_reward(run_state: Dictionary, card_id: String, relic_id: String = "") -> String:
	var reward: Dictionary = run_state.get("pending_reward_state", {})
	var candidate_cards: Array = reward.get("candidate_card_ids", [])
	if not card_id.is_empty() and candidate_cards.has(card_id):
		run_state["deck_state"]["master_deck"].append(card_id)
	var currency_amount := int(reward.get("currency_amount", 0))
	if reward.get("source_node_type", "") == "elite_battle" and run_state.get("owned_relic_ids", []).has("relic_parking_pass"):
		currency_amount += 15
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) + currency_amount
	var relics: Array = reward.get("candidate_relic_ids", [])
	if not relic_id.is_empty() and relics.has(relic_id) and not run_state.get("owned_relic_ids", []).has(relic_id):
		run_state["owned_relic_ids"].append(relic_id)
	var counters: Dictionary = run_state.get("run_counters", {})
	if reward.get("source_node_type", "") == "elite_battle":
		counters["elite_wins"] = int(counters.get("elite_wins", 0)) + 1
	run_state["run_counters"] = counters
	run_state["pending_reward_state"] = {}
	var result := map_service.complete_current_node(run_state)
	if result == "run_victory":
		run_state["run_flags"]["victory"] = true
	return result

func prepare_shop_stock(run_state: Dictionary) -> void:
	if not run_state.get("shop_state", {}).is_empty():
		return
	run_state["shop_state"] = _roll_shop_stock(run_state)

func _roll_shop_stock(run_state: Dictionary) -> Dictionary:
	var cards: Array = content_resolver.cards_for_run_class(run_state.get("selected_class_id", ""), true)
	cards.shuffle()
	var relics: Array = content_resolver.relics_for_run_class(run_state.get("selected_class_id", ""))
	var owned_relics: Array = run_state.get("owned_relic_ids", [])
	relics = relics.filter(func(relic): return not owned_relics.has(relic.get("id", "")))
	relics.shuffle()
	return {
		"card_stock": cards.slice(0, min(5, cards.size())).map(func(card): return card.get("id", "")),
		"relic_stock": relics.slice(0, min(3, relics.size())).map(func(relic): return relic.get("id", "")),
		"removed": false,
		"refresh_count": 0,
	}

func shop_refresh_cost(_run_state: Dictionary = {}) -> int:
	var pool: Dictionary = content_resolver.shop_pool("shop_default")
	return int(pool.get("refresh_cost", 20))

func refresh_shop_stock(run_state: Dictionary) -> bool:
	prepare_shop_stock(run_state)
	var cost: int = shop_refresh_cost(run_state)
	if int(run_state.get("currency_perf_points", 0)) < cost:
		return false
	var previous_state: Dictionary = run_state.get("shop_state", {})
	var removed := bool(previous_state.get("removed", false))
	var discount_used := bool(previous_state.get("discount_used", false))
	var refresh_count := int(previous_state.get("refresh_count", 0)) + 1
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - cost
	run_state["shop_state"] = _roll_shop_stock(run_state)
	run_state["shop_state"]["removed"] = removed
	run_state["shop_state"]["refresh_count"] = refresh_count
	if discount_used:
		run_state["shop_state"]["discount_used"] = true
	return true

func buy_shop_card(run_state: Dictionary, card_id: String) -> bool:
	prepare_shop_stock(run_state)
	var cost := card_cost(run_state)
	if int(run_state.get("currency_perf_points", 0)) < cost:
		return false
	var stock: Array = run_state["shop_state"].get("card_stock", [])
	if not stock.has(card_id):
		return false
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - cost
	_mark_shop_discount_used(run_state)
	run_state["deck_state"]["master_deck"].append(card_id)
	stock.erase(card_id)
	run_state["shop_state"]["card_stock"] = stock
	return true

func buy_shop_relic(run_state: Dictionary, relic_id: String) -> bool:
	prepare_shop_stock(run_state)
	var cost := relic_cost(run_state)
	if int(run_state.get("currency_perf_points", 0)) < cost:
		return false
	if run_state.get("owned_relic_ids", []).has(relic_id):
		return false
	var stock: Array = run_state["shop_state"].get("relic_stock", [])
	if not stock.has(relic_id):
		return false
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - cost
	_mark_shop_discount_used(run_state)
	run_state["owned_relic_ids"].append(relic_id)
	stock.erase(relic_id)
	run_state["shop_state"]["relic_stock"] = stock
	return true

func remove_shop_card(run_state: Dictionary, card_id: String = "") -> bool:
	prepare_shop_stock(run_state)
	var cost: int = remove_cost(run_state)
	if int(run_state.get("currency_perf_points", 0)) < cost:
		return false
	if bool(run_state["shop_state"].get("removed", false)):
		return false
	var deck: Array = run_state["deck_state"].get("master_deck", [])
	if deck.is_empty():
		return false
	var target_index: int = deck.size() - 1
	if not card_id.is_empty():
		target_index = -1
		for i in deck.size():
			if String(deck[i]) == card_id:
				target_index = i
				break
		if target_index == -1:
			return false
	var removed_card_id := String(deck[target_index])
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - cost
	_mark_shop_discount_used(run_state)
	deck.remove_at(target_index)
	run_state["deck_state"]["master_deck"] = deck
	run_state["deck_state"]["removed_cards"].append(removed_card_id)
	run_state["shop_state"]["removed"] = true
	return true

func leave_shop(run_state: Dictionary) -> String:
	run_state["shop_state"] = {}
	var counters: Dictionary = run_state.get("run_counters", {})
	counters["shops_visited"] = int(counters.get("shops_visited", 0)) + 1
	run_state["run_counters"] = counters
	return map_service.complete_current_node(run_state)

func prepare_event(run_state: Dictionary) -> void:
	if not run_state.get("event_state", {}).is_empty():
		return
	var events: Array = content_resolver.events_for_run_class(
		run_state.get("selected_class_id", ""),
		int(run_state.get("current_chapter", 1))
	)
	events.shuffle()
	if events.is_empty():
		run_state["event_state"] = {}
	else:
		run_state["event_state"] = { "event_id": events[0].get("id", "") }

func choose_event_option(run_state: Dictionary, option_index: int) -> String:
	prepare_event(run_state)
	var event := current_event(run_state)
	if event.is_empty():
		return map_service.complete_current_node(run_state)
	var options: Array = event.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return ""
	var option: Dictionary = options[option_index]
	for entry in option.get("effects", []):
		_apply_event_effect(run_state, entry)
	var history: Array = run_state.get("event_history_ids", [])
	history.append(run_state.get("event_state", {}).get("event_id", ""))
	run_state["event_history_ids"] = history
	var counters: Dictionary = run_state.get("run_counters", {})
	counters["events_resolved"] = int(counters.get("events_resolved", 0)) + 1
	run_state["run_counters"] = counters
	run_state["event_state"] = {}
	return map_service.complete_current_node(run_state)

func current_event(run_state: Dictionary) -> Dictionary:
	var event_id := String(run_state.get("event_state", {}).get("event_id", ""))
	return content_resolver.event_def(event_id)

func rest_recover(run_state: Dictionary) -> String:
	var ps: Dictionary = run_state.get("player_state", {})
	var amount: int = int(float(ps.get("max_spirit", 72)) * 0.3) + meta_service.get_upgrade_level("meta_nap_bed") * 4
	ps["current_spirit"] = min(int(ps.get("max_spirit", 72)), int(ps.get("current_spirit", 72)) + amount)
	run_state["player_state"] = ps
	_count_rest(run_state)
	return map_service.complete_current_node(run_state)

func rest_upgrade(run_state: Dictionary) -> String:
	for card_id in run_state["deck_state"]["master_deck"]:
		if _upgrade_card_id(run_state, card_id):
			break
	_count_rest(run_state)
	return map_service.complete_current_node(run_state)

func rest_upgrade_card(run_state: Dictionary, card_id: String) -> String:
	_upgrade_card_id(run_state, card_id)
	_count_rest(run_state)
	return map_service.complete_current_node(run_state)

func _upgrade_card_id(run_state: Dictionary, card_id: String) -> bool:
	if card_id.is_empty():
		return false
	if not run_state["deck_state"]["master_deck"].has(card_id):
		return false
	if run_state["deck_state"]["upgraded_cards"].has(card_id):
		return false
	run_state["deck_state"]["upgraded_cards"].append(card_id)
	return true

func card_cost(run_state: Dictionary) -> int:
	return max(1, CARD_COST - _shop_discount(run_state))

func relic_cost(run_state: Dictionary) -> int:
	return max(1, RELIC_COST - _shop_discount(run_state))

func remove_cost(run_state: Dictionary) -> int:
	return max(1, REMOVE_COST - _shop_discount(run_state))

func _shop_discount(run_state: Dictionary) -> int:
	if bool(run_state.get("shop_state", {}).get("discount_used", false)):
		return 0
	var discount := 0
	if run_state.get("owned_relic_ids", []).has("relic_employee_coupon"):
		discount += 15
	discount += meta_service.get_upgrade_level("meta_canteen_card") * 5
	return discount

func _mark_shop_discount_used(run_state: Dictionary) -> void:
	if _shop_discount(run_state) <= 0:
		return
	run_state["shop_state"]["discount_used"] = true

func _count_rest(run_state: Dictionary) -> void:
	var counters: Dictionary = run_state.get("run_counters", {})
	counters["rests_used"] = int(counters.get("rests_used", 0)) + 1
	run_state["run_counters"] = counters

func _apply_event_effect(run_state: Dictionary, entry: Dictionary) -> void:
	var params: Dictionary = entry.get("params", {})
	var amount: int = int(params.get("amount", 0))
	match entry.get("effect_type", ""):
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
		"add_random_card":
			_add_random_cards(run_state, max(1, amount))
		"draw_cards":
			_add_random_cards(run_state, max(1, amount))
		"add_random_relic":
			_add_random_relics(run_state, max(1, amount))
		"remove_card":
			_remove_cards(run_state, max(1, amount))
		"upgrade_card":
			_upgrade_cards(run_state, max(1, amount))

func _add_random_cards(run_state: Dictionary, amount: int) -> void:
	var cards: Array = content_resolver.cards_for_run_class(run_state.get("selected_class_id", ""), true)
	cards.shuffle()
	for i in range(min(max(1, amount), cards.size())):
		run_state["deck_state"]["master_deck"].append(cards[i].get("id", ""))

func _add_random_relics(run_state: Dictionary, amount: int) -> void:
	var relics: Array = content_resolver.relics_for_run_class(run_state.get("selected_class_id", ""))
	relics.shuffle()
	var owned: Array = run_state.get("owned_relic_ids", [])
	var added := 0
	for relic in relics:
		if added >= amount:
			break
		var relic_id := String(relic.get("id", ""))
		if relic_id.is_empty() or owned.has(relic_id):
			continue
		owned.append(relic_id)
		added += 1
	run_state["owned_relic_ids"] = owned

func _remove_cards(run_state: Dictionary, amount: int) -> void:
	for i in range(max(1, amount)):
		if run_state["deck_state"]["master_deck"].is_empty():
			return
		var removed = run_state["deck_state"]["master_deck"].pop_back()
		run_state["deck_state"]["removed_cards"].append(removed)

func _upgrade_cards(run_state: Dictionary, amount: int) -> void:
	var upgraded := 0
	for card_id in run_state["deck_state"]["master_deck"]:
		if upgraded >= amount:
			break
		if _upgrade_card_id(run_state, String(card_id)):
			upgraded += 1
