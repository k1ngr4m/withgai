extends Control

func _ready() -> void:
	_prepare_event()
	_build()

func _prepare_event() -> void:
	AppRoot.reward_service.prepare_event(AppRoot.run_session.run_state)
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _build() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_battle_ch1_open_office_v1.png")
	var run := AppRoot.run_session.run_state
	var event: Dictionary = AppRoot.reward_service.current_event(run)
	var margin := UiFactory.margin(self, 36)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(UiFactory.label(event.get("name", "随机事件"), 32))
	main.add_child(UiFactory.label(event.get("text", ""), 20, Color(0.88, 0.94, 0.95)))
	var options: Array = event.get("options", [])
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var b: Button = UiFactory.button(option.get("text", "选择"))
		b.pressed.connect(func(): _choose(i))
		main.add_child(b)
	var actions := UiFactory.hbox(8)
	main.add_child(actions)
	var save := UiFactory.button("保存")
	save.pressed.connect(_save_event)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)

func _choose(option_index: int) -> void:
	AppRoot.reward_service.choose_event_option(AppRoot.run_session.run_state, option_index)
	AppRoot.flow_controller.show_scene("map")

func _save_event() -> void:
	AppRoot.run_session.run_state["current_scene_tag"] = "event"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	_save_event()
	AppRoot.flow_controller.show_scene("main_menu")
