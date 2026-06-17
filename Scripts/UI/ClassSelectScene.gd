extends Control

const FrameAnimatorScript := preload("res://Scripts/UI/FrameAnimator.gd")

const CLASS_SPRITE_BUNDLES := {
	"backend": "res://Resources/Art/Generated/P1/sprites/char_backend_sprite_bundle_v1",
	"frontend": "res://Resources/Art/Generated/P1/sprites/char_frontend_sprite_bundle_v1",
	"tester": "res://Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1",
	"algorithm": "res://Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1",
	"product_manager": "res://Resources/Art/Generated/P1/sprites/char_product_manager_sprite_bundle_v1",
	"hr": "res://Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1",
}
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
	call_deferred("_animate_entry")

func _class_card(cls: Dictionary) -> Control:
	var panel := UiFactory.panel()
	panel.custom_minimum_size = Vector2(230, 520)
	var box := UiFactory.vbox(8)
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var class_id := String(cls.get("id", ""))
	box.add_child(_class_preview_art(class_id))
	box.add_child(UiFactory.label("%s  难度 %d" % [cls.get("name", class_id), int(cls.get("recommended_difficulty", 1))], 22))
	box.add_child(UiFactory.label(cls.get("summary", ""), 15, Color(0.85, 0.9, 0.92)))
	box.add_child(UiFactory.label("初始遗物：%s" % AppRoot.config_service.get_def("relics", cls.get("starter_relic_id", "")).get("name", "无"), 14, Color(0.75, 0.88, 0.9)))
	box.add_child(UiFactory.label("状态：%s" % AppRoot.meta_service.class_availability_label(cls), 14, _availability_color(cls)))
	box.add_child(UiFactory.label("条件：%s" % AppRoot.meta_service.class_unlock_label(cls), 13, Color(0.72, 0.83, 0.86)))
	box.add_child(UiFactory.label("进度：%s" % AppRoot.meta_service.class_unlock_progress(cls), 13, Color(0.72, 0.83, 0.86)))
	var button := UiFactory.button("开始")
	var disabled := not AppRoot.meta_service.is_class_playable(class_id)
	if disabled:
		button.text = AppRoot.meta_service.class_availability_label(cls)
		panel.modulate = Color(0.72, 0.78, 0.82, 0.88)
	else:
		UiMotion.apply_panel_style(panel, Color(0.38, 0.86, 0.92, 0.84))
	button.pressed.connect(func(): _start_class(class_id, panel))
	box.add_child(button)
	return panel

func _class_preview_art(class_id: String) -> Control:
	var frames := _processed_action_frames(String(CLASS_SPRITE_BUNDLES.get(class_id, "")), "idle")
	if not frames.is_empty():
		var animator: FrameAnimator = FrameAnimatorScript.new()
		animator.name = "ClassPreviewAnimator%s" % class_id.capitalize()
		animator.setup_actions({ "idle": frames }, String(CLASS_ART.get(class_id, "")), 6, Vector2(210, 190))
		return animator
	return UiFactory.texture(CLASS_ART.get(class_id, ""), Vector2(210, 190))

func _processed_action_frames(base: String, action: String) -> Array:
	var frames: Array = []
	if base.is_empty():
		return frames
	var processed := "%s/%s/processed" % [base, action]
	for i in range(1, 9):
		var path := "%s/%s-%d.png" % [processed, action, i]
		if ResourceLoader.exists(path):
			frames.append(path)
	return frames

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

func _start_class(class_id: String, source: Control = null) -> void:
	if not AppRoot.meta_service.is_class_playable(class_id):
		if source != null:
			UiMotion.shake(source, 8.0, 0.12)
		return
	if source != null:
		UiMotion.pop_in(source, 0.18)
	AppRoot.reset_run()
	var run: Dictionary = AppRoot.run_session.create_new_run(class_id)
	if run.is_empty():
		return
	AppRoot.save_service.save_suspend(run, AppRoot.meta_service.meta_state)
	AppRoot.flow_controller.show_scene("map")

func _animate_entry() -> void:
	var cards := find_children("*", "PanelContainer", true, false)
	var delay := 0.0
	for card in cards:
		var captured = card
		var tween := card.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func(): UiMotion.fade_in(captured, 0.18, Vector2(16, 0)))
		delay += 0.04
