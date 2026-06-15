extends Control

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
	for card_id in run["shop_state"].get("card_stock", []):
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var b: Button = UiFactory.button("买卡 %d\n%s\n%s" % [card_cost, card.get("name", card_id), card.get("description", "")])
		b.custom_minimum_size = Vector2(210, 170)
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
	var actions := UiFactory.hbox(8)
	main.add_child(actions)
	var remove := UiFactory.button("移除一张牌 %d" % remove_cost)
	remove.disabled = int(run.get("currency_perf_points", 0)) < remove_cost or run["shop_state"].get("removed", false)
	remove.pressed.connect(_remove_card)
	actions.add_child(remove)
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
	AppRoot.reward_service.remove_shop_card(AppRoot.run_session.run_state)
	_build()

func _leave() -> void:
	AppRoot.reward_service.leave_shop(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("map")
