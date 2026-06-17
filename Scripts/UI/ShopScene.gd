extends Control

var selected_remove_card_id: String = ""
var _last_shop_feedback := ""

func _ready() -> void:
	if not _has_shop_run():
		return
	_prepare_stock()
	_build()


func _has_shop_run() -> bool:
	if AppRoot.run_session == null:
		return false
	var run: Dictionary = AppRoot.run_session.run_state
	return not run.is_empty() and run.has("deck_state") and run.has("shop_state")


func _prepare_stock() -> void:
	AppRoot.reward_service.prepare_shop_stock(AppRoot.run_session.run_state)
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_shop_vending_machine_v1.png")
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 24)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	var card_cost := AppRoot.reward_service.card_cost(run)
	var relic_cost := AppRoot.reward_service.relic_cost(run)
	var remove_cost := AppRoot.reward_service.remove_cost(run)
	var refresh_cost := AppRoot.reward_service.shop_refresh_cost(run)
	var deck_cards: Array = run.get("deck_state", {}).get("master_deck", [])
	if not selected_remove_card_id.is_empty() and not deck_cards.has(selected_remove_card_id):
		selected_remove_card_id = ""
	main.add_child(_shop_header())
	main.add_child(_player_currency_panel(run, card_cost, relic_cost, remove_cost, refresh_cost))
	main.add_child(_shop_stock_panel(run, card_cost, relic_cost))
	main.add_child(_build_remove_picker(run, remove_cost))
	main.add_child(_shop_action_bar(run, remove_cost, refresh_cost, deck_cards))
	call_deferred("_animate_entry")


func _shop_header() -> Label:
	var label := UiFactory.label("深夜工位商店", 30)
	label.name = "ShopHeader"
	return label


func _player_currency_panel(run: Dictionary, card_cost: int, relic_cost: int, remove_cost: int, refresh_cost: int) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "PlayerCurrencyPanel"
	var box := UiFactory.vbox(5)
	panel.add_child(box)
	box.add_child(UiFactory.label("绩效点 %d" % int(run.get("currency_perf_points", 0)), 22, Color(1.0, 0.9, 0.55)))
	box.add_child(UiFactory.label("买卡 %d | 买遗物 %d | 删牌 %d | 刷新 %d" % [card_cost, relic_cost, remove_cost, refresh_cost], 14, Color(0.82, 0.92, 0.94)))
	box.add_child(UiFactory.label("牌组 %d 张 | 遗物 %d 件 | 刷新次数 %d" % [
		int(run.get("deck_state", {}).get("master_deck", []).size()),
		int(run.get("owned_relic_ids", []).size()),
		int(run.get("shop_state", {}).get("refresh_count", 0)),
	], 14, Color(0.72, 0.84, 0.86)))
	return panel


func _shop_stock_panel(run: Dictionary, card_cost: int, relic_cost: int) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "ShopStockPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("货架", 22, Color(0.86, 0.94, 0.98)))
	var row := UiFactory.hbox(10)
	row.name = "ShopStockRow"
	box.add_child(UiFactory.scroll(row))
	var shop_state: Dictionary = run.get("shop_state", {})
	for card_id in shop_state.get("card_stock", []):
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var b: Button = UiFactory.card_button(card, "买卡 %d\n%s\n%s" % [card_cost, card.get("name", card_id), card.get("description", "")], Vector2(210, 170))
		b.name = "ShopCardButton"
		b.disabled = int(run.get("currency_perf_points", 0)) < card_cost
		b.pressed.connect(func(): _buy_card(card_id))
		row.add_child(b)
	for relic_id in shop_state.get("relic_stock", []):
		var relic: Dictionary = AppRoot.config_service.get_def("relics", relic_id)
		var b2: Button = UiFactory.button("买遗物 %d\n%s\n%s" % [relic_cost, relic.get("name", relic_id), relic.get("description", "")])
		b2.name = "ShopRelicButton"
		b2.custom_minimum_size = Vector2(210, 170)
		b2.disabled = int(run.get("currency_perf_points", 0)) < relic_cost or run.get("owned_relic_ids", []).has(relic_id)
		b2.pressed.connect(func(): _buy_relic(relic_id))
		row.add_child(b2)
	return panel


func _shop_action_bar(run: Dictionary, remove_cost: int, refresh_cost: int, deck_cards: Array) -> Control:
	var actions := UiFactory.hbox(8)
	actions.name = "ShopActionBar"
	var remove_label := "移除所选牌 %d" % remove_cost
	if selected_remove_card_id.is_empty():
		remove_label = "选择要移除的牌"
	var remove := UiFactory.button(remove_label)
	remove.name = "RemoveSelectedCardButton"
	remove.disabled = (
		int(run.get("currency_perf_points", 0)) < remove_cost
		or bool(run.get("shop_state", {}).get("removed", false))
		or deck_cards.is_empty()
		or selected_remove_card_id.is_empty()
	)
	remove.pressed.connect(_remove_card)
	actions.add_child(remove)
	var refresh := UiFactory.button("刷新商品 %d" % refresh_cost)
	refresh.name = "RefreshButton"
	refresh.disabled = int(run.get("currency_perf_points", 0)) < refresh_cost
	refresh.pressed.connect(_refresh_stock)
	actions.add_child(refresh)
	var leave := UiFactory.button("离开商店")
	leave.name = "LeaveShopButton"
	leave.pressed.connect(_leave)
	actions.add_child(leave)
	var save := UiFactory.button("保存")
	save.name = "SaveShopButton"
	save.pressed.connect(_save_shop)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "ShopMainMenuButton"
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)
	return actions

func _buy_card(card_id: String) -> void:
	if AppRoot.reward_service.buy_shop_card(AppRoot.run_session.run_state, card_id):
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_last_shop_feedback = "buy"
	else:
		_last_shop_feedback = "fail"
	_build()

func _buy_relic(relic_id: String) -> void:
	if AppRoot.reward_service.buy_shop_relic(AppRoot.run_session.run_state, relic_id):
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_last_shop_feedback = "buy"
	else:
		_last_shop_feedback = "fail"
	_build()

func _remove_card() -> void:
	if AppRoot.reward_service.remove_shop_card(AppRoot.run_session.run_state, selected_remove_card_id):
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_last_shop_feedback = "remove"
	else:
		_last_shop_feedback = "fail"
	selected_remove_card_id = ""
	_build()

func _refresh_stock() -> void:
	if AppRoot.reward_service.refresh_shop_stock(AppRoot.run_session.run_state):
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_last_shop_feedback = "refresh"
	else:
		_last_shop_feedback = "fail"
	_build()

func _leave() -> void:
	AppRoot.reward_service.leave_shop(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("map")

func _save_shop() -> void:
	AppRoot.run_session.run_state["current_scene_tag"] = "shop"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	_save_shop()
	AppRoot.flow_controller.show_scene("main_menu")

func _select_remove_card(card_id: String) -> void:
	selected_remove_card_id = card_id
	_last_shop_feedback = "select_remove"
	_build()

func _build_remove_picker(run: Dictionary, remove_cost: int) -> PanelContainer:
	var deck_cards: Array = run.get("deck_state", {}).get("master_deck", [])
	var panel := UiFactory.panel()
	panel.name = "DeckOperationPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	var status_text := "牌组维护 | 移除费用 %d" % remove_cost
	if bool(run.get("shop_state", {}).get("removed", false)):
		status_text = "牌组维护 | 本次商店已移除过卡牌"
	elif deck_cards.is_empty():
		status_text = "牌组维护 | 当前牌组为空"
	box.add_child(UiFactory.label(status_text, 18, Color(0.92, 0.95, 0.98)))
	if deck_cards.is_empty():
		return panel
	var unique_cards: Array = []
	for card_id in deck_cards:
		if not unique_cards.has(card_id):
			unique_cards.append(card_id)
	var grid := GridContainer.new()
	grid.name = "DeckRemoveGrid"
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
		button.name = "DeckRemoveCardButton"
		button.disabled = bool(run.get("shop_state", {}).get("removed", false))
		button.pressed.connect(func(): _select_remove_card(String(card_id)))
		grid.add_child(button)
	return panel

func _count_deck_card(deck_cards: Array, card_id: String) -> int:
	var count := 0
	for item in deck_cards:
		if String(item) == card_id:
			count += 1
	return count

func _animate_entry() -> void:
	var stock := find_child("ShopStockRow", true, false)
	if stock != null:
		var delay := 0.0
		for child in stock.get_children():
			if child is Control:
				var captured = child
				var tween := child.create_tween()
				tween.tween_interval(delay)
				tween.tween_callback(func(): UiMotion.fade_in(captured, 0.18, Vector2(18, 0)))
				delay += 0.04
	var currency := find_child("PlayerCurrencyPanel", true, false)
	if currency != null:
		match _last_shop_feedback:
			"buy", "refresh", "remove":
				UiMotion.pulse(currency, UiMotion.REWARD if _last_shop_feedback == "buy" else UiMotion.REQUEST, 0.18)
			"fail":
				UiMotion.shake(currency, 8.0, 0.12)
	var remove_grid := find_child("DeckRemoveGrid", true, false)
	if remove_grid != null and _last_shop_feedback == "select_remove":
		UiMotion.scan_line(remove_grid, UiMotion.BLOCK, 0.16)
	if _last_shop_feedback == "refresh":
		UiMotion.scan_line(self, UiMotion.REQUEST, 0.20)
	_last_shop_feedback = ""
