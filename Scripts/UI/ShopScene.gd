extends Control

var selected_remove_card_id: String = ""

func _ready() -> void:
	_prepare_stock()
	_build()

func _prepare_stock() -> void:
	AppRoot.reward_service.prepare_shop_stock(AppRoot.run_session.run_state)

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_shop_vending_machine_v1.png")
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 24)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(UiFactory.label("深夜工位商店 | 绩效点 %d" % int(run.get("currency_perf_points", 0)), 30))
	var row := UiFactory.hbox(10)
	main.add_child(UiFactory.scroll(row))
	var card_cost := AppRoot.reward_service.card_cost(run)
	var relic_cost := AppRoot.reward_service.relic_cost(run)
	var remove_cost := AppRoot.reward_service.remove_cost(run)
	var refresh_cost := AppRoot.reward_service.shop_refresh_cost(run)
	var deck_cards: Array = run["deck_state"].get("master_deck", [])
	if not selected_remove_card_id.is_empty() and not deck_cards.has(selected_remove_card_id):
		selected_remove_card_id = ""
	main.add_child(UiFactory.label("刷新次数 %d | 刷新花费 %d" % [int(run["shop_state"].get("refresh_count", 0)), refresh_cost], 16, Color(0.84, 0.92, 0.94)))
	for card_id in run["shop_state"].get("card_stock", []):
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var b: Button = UiFactory.card_button(card, "买卡 %d\n%s\n%s" % [card_cost, card.get("name", card_id), card.get("description", "")], Vector2(210, 170))
		b.disabled = int(run.get("currency_perf_points", 0)) < card_cost
		b.pressed.connect(func(): _buy_card(card_id))
		row.add_child(b)
	for relic_id in run["shop_state"].get("relic_stock", []):
		var relic: Dictionary = AppRoot.config_service.get_def("relics", relic_id)
		var b2: Button = UiFactory.button("买遗物 %d\n%s\n%s" % [relic_cost, relic.get("name", relic_id), relic.get("description", "")])
		b2.custom_minimum_size = Vector2(210, 170)
		b2.disabled = int(run.get("currency_perf_points", 0)) < relic_cost or run.get("owned_relic_ids", []).has(relic_id)
		b2.pressed.connect(func(): _buy_relic(relic_id))
		row.add_child(b2)
	_build_remove_picker(main, run, remove_cost)
	var actions := UiFactory.hbox(8)
	main.add_child(actions)
	var remove_label := "移除所选牌 %d" % remove_cost
	if selected_remove_card_id.is_empty():
		remove_label = "选择要移除的牌"
	var remove := UiFactory.button(remove_label)
	remove.disabled = (
		int(run.get("currency_perf_points", 0)) < remove_cost
		or bool(run["shop_state"].get("removed", false))
		or deck_cards.is_empty()
		or selected_remove_card_id.is_empty()
	)
	remove.pressed.connect(_remove_card)
	actions.add_child(remove)
	var refresh := UiFactory.button("刷新商品 %d" % refresh_cost)
	refresh.disabled = int(run.get("currency_perf_points", 0)) < refresh_cost
	refresh.pressed.connect(_refresh_stock)
	actions.add_child(refresh)
	var leave := UiFactory.button("离开商店")
	leave.pressed.connect(_leave)
	actions.add_child(leave)

func _buy_card(card_id: String) -> void:
	AppRoot.reward_service.buy_shop_card(AppRoot.run_session.run_state, card_id)
	_build()

func _buy_relic(relic_id: String) -> void:
	AppRoot.reward_service.buy_shop_relic(AppRoot.run_session.run_state, relic_id)
	_build()

func _remove_card() -> void:
	AppRoot.reward_service.remove_shop_card(AppRoot.run_session.run_state, selected_remove_card_id)
	selected_remove_card_id = ""
	_build()

func _refresh_stock() -> void:
	AppRoot.reward_service.refresh_shop_stock(AppRoot.run_session.run_state)
	_build()

func _leave() -> void:
	AppRoot.reward_service.leave_shop(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("map")

func _select_remove_card(card_id: String) -> void:
	selected_remove_card_id = card_id
	_build()

func _build_remove_picker(parent: VBoxContainer, run: Dictionary, remove_cost: int) -> void:
	var deck_cards: Array = run["deck_state"].get("master_deck", [])
	var panel := UiFactory.panel()
	parent.add_child(panel)
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	var status_text := "牌组维护 | 移除费用 %d" % remove_cost
	if bool(run["shop_state"].get("removed", false)):
		status_text = "牌组维护 | 本次商店已移除过卡牌"
	elif deck_cards.is_empty():
		status_text = "牌组维护 | 当前牌组为空"
	box.add_child(UiFactory.label(status_text, 18, Color(0.92, 0.95, 0.98)))
	if deck_cards.is_empty():
		return
	var unique_cards: Array = []
	for card_id in deck_cards:
		if not unique_cards.has(card_id):
			unique_cards.append(card_id)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for card_id in unique_cards:
		var card: Dictionary = AppRoot.config_service.get_def("cards", String(card_id))
		var count := _count_deck_card(deck_cards, String(card_id))
		var prefix := "○"
		if selected_remove_card_id == String(card_id):
			prefix = "✓"
		var button := UiFactory.card_button(card, "%s %s x%d\n%s" % [prefix, card.get("name", card_id), count, card.get("type", "")], Vector2(210, 72))
		button.disabled = bool(run["shop_state"].get("removed", false))
		button.pressed.connect(func(): _select_remove_card(String(card_id)))
		grid.add_child(button)

func _count_deck_card(deck_cards: Array, card_id: String) -> int:
	var count := 0
	for item in deck_cards:
		if String(item) == card_id:
			count += 1
	return count
