extends Control

const CLASS_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_bust_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_bust_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_bust_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_bust_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_bust_v1/final.png",
	"hr": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
}

func _ready() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_bg_v1.png")
	var margin := UiFactory.margin(self, 24)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(UiFactory.label("选择本局职业", 34))
	main.add_child(UiFactory.label("当前仅后端开放；前端 / 测试 / 算法 / 产品经理先作为占位锁定。", 18, Color(0.86, 0.93, 0.96)))
	var row := UiFactory.hbox(12)
	main.add_child(UiFactory.scroll(row))
	for cls in AppRoot.config_service.first_playable_classes(true):
		row.add_child(_class_card(cls))
	var back := UiFactory.button("返回")
	back.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	main.add_child(back)

func _class_card(cls: Dictionary) -> Control:
	var panel := UiFactory.panel()
	panel.custom_minimum_size = Vector2(230, 520)
	var box := UiFactory.vbox(8)
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var class_id := String(cls.get("id", ""))
	box.add_child(UiFactory.texture(CLASS_ART.get(class_id, ""), Vector2(210, 190)))
	box.add_child(UiFactory.label("%s  难度 %d" % [cls.get("name", class_id), int(cls.get("recommended_difficulty", 1))], 22))
	box.add_child(UiFactory.label(cls.get("summary", ""), 15, Color(0.85, 0.9, 0.92)))
	box.add_child(UiFactory.label("初始遗物：%s" % AppRoot.config_service.get_def("relics", cls.get("starter_relic_id", "")).get("name", "无"), 14, Color(0.75, 0.88, 0.9)))
	box.add_child(UiFactory.label("状态：%s" % AppRoot.meta_service.class_availability_label(cls), 14, _availability_color(cls)))
	box.add_child(UiFactory.label("条件：%s" % AppRoot.meta_service.class_unlock_label(cls), 13, Color(0.72, 0.83, 0.86)))
	box.add_child(UiFactory.label("进度：%s" % AppRoot.meta_service.class_unlock_progress(cls), 13, Color(0.72, 0.83, 0.86)))
	var button := UiFactory.button("开始")
	var disabled := not AppRoot.meta_service.is_class_playable(class_id)
	button.disabled = disabled
	if disabled:
		button.text = AppRoot.meta_service.class_availability_label(cls)
	button.pressed.connect(func(): _start_class(class_id))
	box.add_child(button)
	return panel

func _availability_color(cls: Dictionary) -> Color:
	match AppRoot.meta_service.class_availability_label(cls):
		"可出战":
			return Color(0.58, 0.95, 0.74)
		"未解锁":
			return Color(0.95, 0.75, 0.42)
		"锁定占位":
			return Color(0.74, 0.78, 0.84)
		"扩展占位":
			return Color(0.74, 0.78, 0.84)
		_:
			return Color(0.68, 0.72, 0.76)

func _start_class(class_id: String) -> void:
	if not AppRoot.meta_service.is_class_playable(class_id):
		return
	var run: Dictionary = AppRoot.run_session.create_new_run(class_id)
	if run.is_empty():
		return
	AppRoot.save_service.save_suspend(run, AppRoot.meta_service.meta_state)
	AppRoot.flow_controller.show_scene("map")
