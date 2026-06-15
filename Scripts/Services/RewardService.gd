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

func accept_battle_reward(run_state: Dictionary, card_id: String) -> String:
	var reward: Dictionary = run_state.get("pending_reward_state", {})
	if not card_id.is_empty():
		run_state["deck_state"]["master_deck"].append(card_id)
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) + int(reward.get("currency_amount", 0))
	var relics: Array = reward.get("candidate_relic_ids", [])
	if not relics.is_empty() and not run_state.get("owned_relic_ids", []).has(relics[0]):
		run_state["owned_relic_ids"].append(relics[0])
	run_state["pending_reward_state"] = {}
	var result := map_service.complete_current_node(run_state)
	if result == "run_victory":
		run_state["run_flags"]["victory"] = true
	return result

func prepare_shop_stock(run_state: Dictionary) -> void:
	if not run_state.get("shop_state", {}).is_empty():
		return
	var cards: Array = content_resolver.cards_for_run_class(run_state.get("selected_class_id", ""), true)
	cards.shuffle()
	var relics: Array = content_resolver.relics_for_run_class(run_state.get("selected_class_id", ""))
	relics.shuffle()
	run_state["shop_state"] = {
		"card_stock": cards.slice(0, min(5, cards.size())).map(func(card): return card.get("id", "")),
		"relic_stock": relics.slice(0, min(3, relics.size())).map(func(relic): return relic.get("id", "")),
		"removed": false,
	}

func buy_shop_card(run_state: Dictionary, card_id: String) -> bool:
	prepare_shop_stock(run_state)
	if int(run_state.get("currency_perf_points", 0)) < CARD_COST:
		return false
	var stock: Array = run_state["shop_state"].get("card_stock", [])
	if not stock.has(card_id):
		return false
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - CARD_COST
	run_state["deck_state"]["master_deck"].append(card_id)
	stock.erase(card_id)
	run_state["shop_state"]["card_stock"] = stock
	return true

func buy_shop_relic(run_state: Dictionary, relic_id: String) -> bool:
	prepare_shop_stock(run_state)
	if int(run_state.get("currency_perf_points", 0)) < RELIC_COST:
		return false
	if run_state.get("owned_relic_ids", []).has(relic_id):
		return false
	var stock: Array = run_state["shop_state"].get("relic_stock", [])
	if not stock.has(relic_id):
		return false
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - RELIC_COST
	run_state["owned_relic_ids"].append(relic_id)
	stock.erase(relic_id)
	run_state["shop_state"]["relic_stock"] = stock
	return true

func remove_shop_card(run_state: Dictionary) -> bool:
	prepare_shop_stock(run_state)
	if int(run_state.get("currency_perf_points", 0)) < REMOVE_COST:
		return false
	if bool(run_state["shop_state"].get("removed", false)):
		return false
	if run_state["deck_state"]["master_deck"].is_empty():
		return false
	run_state["currency_perf_points"] = int(run_state.get("currency_perf_points", 0)) - REMOVE_COST
	var removed = run_state["deck_state"]["master_deck"].pop_back()
	run_state["deck_state"]["removed_cards"].append(removed)
	run_state["shop_state"]["removed"] = true
	return true

func leave_shop(run_state: Dictionary) -> String:
	run_state["shop_state"] = {}
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
	return map_service.complete_current_node(run_state)

func rest_upgrade(run_state: Dictionary) -> String:
	for card_id in run_state["deck_state"]["master_deck"]:
		if not run_state["deck_state"]["upgraded_cards"].has(card_id):
			run_state["deck_state"]["upgraded_cards"].append(card_id)
			break
	return map_service.complete_current_node(run_state)

func _apply_event_effect(run_state: Dictionary, entry: Dictionary) -> void:
	var params: Dictionary = entry.get("params", {})
	var amount := int(params.get("amount", 0))
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
			var cards: Array = content_resolver.cards_for_run_class(run_state.get("selected_class_id", ""), true)
			cards.shuffle()
			if not cards.is_empty():
				run_state["deck_state"]["master_deck"].append(cards[0].get("id", ""))
		"add_random_relic":
			var relics: Array = content_resolver.relics_for_run_class(run_state.get("selected_class_id", ""))
			relics.shuffle()
			if not relics.is_empty():
				run_state["owned_relic_ids"].append(relics[0].get("id", ""))
		"remove_card":
			if not run_state["deck_state"]["master_deck"].is_empty():
				run_state["deck_state"]["removed_cards"].append(run_state["deck_state"]["master_deck"].pop_back())
		"upgrade_card":
			if not run_state["deck_state"]["master_deck"].is_empty():
				run_state["deck_state"]["upgraded_cards"].append(run_state["deck_state"]["master_deck"][0])
