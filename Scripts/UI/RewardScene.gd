extends Control

func _ready() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_reward_bg_v1.png")
	var margin := UiFactory.margin(self, 28)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	var reward: Dictionary = AppRoot.run_session.run_state.get("pending_reward_state", {})
	main.add_child(UiFactory.label("战斗奖励", 34))
	main.add_child(UiFactory.label("绩效点 +%d" % int(reward.get("currency_amount", 0)), 22, Color(1.0, 0.9, 0.55)))
	var row := UiFactory.hbox(10)
	main.add_child(row)
	for card_id in reward.get("candidate_card_ids", []):
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var b: Button = UiFactory.button("%s\n%s\n%s" % [card.get("name", card_id), card.get("type", ""), card.get("description", "")])
		b.custom_minimum_size = Vector2(230, 180)
		b.pressed.connect(func(): _accept_reward(card_id))
		row.add_child(b)
	var relics: Array = reward.get("candidate_relic_ids", [])
	if not relics.is_empty():
		var relic: Dictionary = AppRoot.config_service.get_def("relics", relics[0])
		main.add_child(UiFactory.label("额外遗物：%s - %s" % [relic.get("name", relics[0]), relic.get("description", "")], 18, Color(0.78, 0.92, 1.0)))
	var skip := UiFactory.button("跳过卡牌并领取绩效点")
	skip.pressed.connect(func(): _accept_reward(""))
	main.add_child(skip)

func _accept_reward(card_id: String) -> void:
	var run := AppRoot.run_session.run_state
	var result: String = AppRoot.reward_service.accept_battle_reward(run, card_id)
	if result == "run_victory":
		AppRoot.flow_controller.show_scene("run_result")
	else:
		AppRoot.save_service.save_suspend(run, AppRoot.meta_service.meta_state)
		AppRoot.flow_controller.show_scene("map")
