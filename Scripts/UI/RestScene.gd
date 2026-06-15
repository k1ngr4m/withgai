extends Control

func _ready() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_rest_break_room_v1.png")
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 36)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(UiFactory.label("休息处", 34))
	main.add_child(UiFactory.label("精神 %d/%d" % [int(run.get("player_state", {}).get("current_spirit", 0)), int(run.get("player_state", {}).get("max_spirit", 0))], 22))
	var recover := UiFactory.button("冥想：恢复精神状态")
	recover.pressed.connect(_recover)
	main.add_child(recover)
	var upgrade := UiFactory.button("复盘：升级一张牌")
	upgrade.pressed.connect(_show_upgrade_choices)
	main.add_child(upgrade)

func _recover() -> void:
	AppRoot.reward_service.rest_recover(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("map")

func _show_upgrade_choices() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_rest_break_room_v1.png")
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 36)
	var main := UiFactory.vbox(10)
	margin.add_child(main)
	main.add_child(UiFactory.label("选择要复盘升级的牌", 30))
	var choices := UiFactory.vbox(6)
	main.add_child(UiFactory.scroll(choices))
	var seen: Array = []
	for card_id in run.get("deck_state", {}).get("master_deck", []):
		if seen.has(card_id):
			continue
		seen.append(card_id)
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var upgraded := run.get("deck_state", {}).get("upgraded_cards", []).has(card_id)
		var b := UiFactory.button("%s%s\n%s" % [card.get("name", card_id), " +" if upgraded else "", card.get("description", "")])
		b.disabled = upgraded
		b.pressed.connect(func(): _upgrade(card_id))
		choices.add_child(b)
	var back := UiFactory.button("返回")
	back.pressed.connect(_ready)
	main.add_child(back)

func _upgrade(card_id: String) -> void:
	AppRoot.reward_service.rest_upgrade_card(AppRoot.run_session.run_state, card_id)
	AppRoot.flow_controller.show_scene("map")
