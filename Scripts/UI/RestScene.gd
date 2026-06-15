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
	upgrade.pressed.connect(_upgrade)
	main.add_child(upgrade)

func _recover() -> void:
	AppRoot.reward_service.rest_recover(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("map")

func _upgrade() -> void:
	AppRoot.reward_service.rest_upgrade(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("map")
