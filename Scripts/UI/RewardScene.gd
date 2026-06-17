extends Control

var selected_card_id: String = ""
var selected_relic_id: String = ""

func _ready() -> void:
	if AppRoot.run_session.run_state.get("pending_reward_state", {}).is_empty():
		AppRoot.flow_controller.show_scene("map")
		return
	selected_card_id = ""
	selected_relic_id = ""
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_reward_bg_v1.png")
	var margin := UiFactory.margin(self, 28)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	var reward: Dictionary = AppRoot.run_session.run_state.get("pending_reward_state", {})
	main.add_child(UiFactory.label("战斗奖励", 34))
	main.add_child(UiFactory.label("绩效点 +%d" % int(reward.get("currency_amount", 0)), 22, Color(1.0, 0.9, 0.55)))
	main.add_child(UiFactory.label("选择一张牌", 22, Color(0.86, 0.94, 0.98)))
	var row := UiFactory.hbox(10)
	main.add_child(row)
	for card_id in reward.get("candidate_card_ids", []):
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var card_marker := "✓ " if selected_card_id == String(card_id) else ""
		var b: Button = UiFactory.card_button(card, "%s%s\n%s\n%s" % [card_marker, card.get("name", card_id), card.get("type", ""), card.get("description", "")], Vector2(230, 180))
		b.pressed.connect(func(): _select_card(String(card_id)))
		row.add_child(b)
	var skip_card := UiFactory.button("跳过卡牌")
	skip_card.pressed.connect(func(): _select_card(""))
	row.add_child(skip_card)
	var relics: Array = reward.get("candidate_relic_ids", [])
	if not relics.is_empty():
		main.add_child(UiFactory.label("选择一件遗物", 22, Color(0.86, 0.94, 0.98)))
		var relic_row := UiFactory.hbox(10)
		main.add_child(relic_row)
		for relic_id in relics:
			var relic: Dictionary = AppRoot.config_service.get_def("relics", relic_id)
			var relic_marker := "✓ " if selected_relic_id == String(relic_id) else ""
			var relic_button: Button = UiFactory.button("%s%s\n%s" % [relic_marker, relic.get("name", relic_id), relic.get("description", "")])
			relic_button.custom_minimum_size = Vector2(260, 130)
			relic_button.pressed.connect(func(): _select_relic(String(relic_id)))
			relic_row.add_child(relic_button)
		var skip_relic := UiFactory.button("跳过遗物")
		skip_relic.pressed.connect(func(): _select_relic(""))
		relic_row.add_child(skip_relic)
	var confirm := UiFactory.button("确认领取")
	confirm.pressed.connect(_accept_reward)
	main.add_child(confirm)
	var actions := UiFactory.hbox(8)
	main.add_child(actions)
	var save := UiFactory.button("保存")
	save.pressed.connect(_save_reward)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)

func _select_card(card_id: String) -> void:
	selected_card_id = card_id
	_build()

func _select_relic(relic_id: String) -> void:
	selected_relic_id = relic_id
	_build()

func _accept_reward() -> void:
	var run := AppRoot.run_session.run_state
	var result: String = AppRoot.reward_service.accept_battle_reward(run, selected_card_id, selected_relic_id)
	if result == "run_victory":
		AppRoot.flow_controller.show_scene("run_result")
	else:
		AppRoot.flow_controller.show_scene("map")

func _save_reward() -> void:
	AppRoot.run_session.run_state["current_scene_tag"] = "reward"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	_save_reward()
	AppRoot.flow_controller.show_scene("main_menu")
