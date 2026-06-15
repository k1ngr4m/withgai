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
	main.add_child(UiFactory.label("五职业已接入 First Playable；HR 作为后续扩展职业展示。", 18, Color(0.86, 0.93, 0.96)))
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
	var button := UiFactory.button("开始")
	var locked := not AppRoot.meta_service.is_class_unlocked(class_id)
	var disabled: bool = locked or not bool(cls.get("enabled_in_first_playable", false))
	button.disabled = disabled
	if disabled:
		button.text = "未开放" if class_id == "hr" else "未解锁"
	button.pressed.connect(func(): _start_class(class_id))
	box.add_child(button)
	return panel

func _start_class(class_id: String) -> void:
	AppRoot.run_session.create_new_run(class_id)
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
	AppRoot.flow_controller.show_scene("map")
