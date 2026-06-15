extends Control

func _ready() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png")
	var margin := UiFactory.margin(self, 48)
	var box := UiFactory.vbox(16)
	margin.add_child(box)
	box.add_child(UiFactory.label("withgai", 56))
	box.add_child(UiFactory.label("写字楼爬楼卡牌肉鸽 First Playable", 22, Color(0.85, 0.92, 0.95)))
	var actions := UiFactory.vbox(10)
	actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(actions)
	var new_button := UiFactory.button("新开一局")
	new_button.pressed.connect(func(): AppRoot.flow_controller.show_scene("class_select"))
	actions.add_child(new_button)
	var continue_button := UiFactory.button("继续中断档")
	continue_button.disabled = not AppRoot.save_service.has_suspend()
	continue_button.pressed.connect(_continue_run)
	actions.add_child(continue_button)
	var meta_button := UiFactory.button("工位成长")
	meta_button.pressed.connect(func(): AppRoot.flow_controller.show_scene("meta"))
	actions.add_child(meta_button)
	var quit_button := UiFactory.button("退出")
	quit_button.pressed.connect(func(): get_tree().quit())
	actions.add_child(quit_button)

func _continue_run() -> void:
	if AppRoot.run_session.restore_from_suspend(AppRoot.save_service.load_suspend()):
		var tag: String = String(AppRoot.run_session.run_state.get("current_scene_tag", "map"))
		AppRoot.flow_controller.show_scene(tag)
