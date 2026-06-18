extends Control

const COMPACT_BREAKPOINT := 1040.0
const SHORT_BREAKPOINT := 760.0
const PLAYER_SPIRIT := 72
const PLAYER_ENERGY := 3

const CLASS_SPRITE_BUNDLES := {
	"backend": "res://Resources/Art/Generated/P1/sprites/char_backend_sprite_bundle_v1",
	"frontend": "res://Resources/Art/Generated/P1/sprites/char_frontend_sprite_bundle_v1",
	"tester": "res://Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1",
	"algorithm": "res://Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1",
	"product_manager": "res://Resources/Art/Generated/P1/sprites/char_product_manager_sprite_bundle_v1",
	"hr": "res://Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1",
}
const CLASS_CHARACTER_BG := {
	"backend": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_backend_character_bg_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_frontend_character_bg_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_tester_character_bg_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_algorithm_character_bg_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_product_manager_character_bg_v1/final.png",
	"hr": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_hr_character_bg_v1/final.png",
}
const CLASS_HEAD_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
	"hr": "res://Resources/Art/Generated/P0/characters/char_hr_head_icon_v1/final.png",
}

var _classes: Array = []
var _selected_index := 0
var _background_rect: TextureRect
var _content_layer: Control
var _detail_panel: PanelContainer
var _name_label: Label
var _summary_label: Label
var _spirit_label: Label
var _energy_label: Label
var _difficulty_label: Label
var _relic_label: Label
var _availability_label: Label
var _unlock_label: Label
var _progress_label: Label
var _confirm_button: Button
var _thumbnail_row: HBoxContainer
var _thumb_buttons: Array = []
var _rebuild_queued := false


func _ready() -> void:
	UiFactory.fill(self)
	_background_rect = TextureRect.new()
	_background_rect.name = "ClassCharacterBackground"
	UiFactory.fill(_background_rect)
	_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background_rect)
	_add_readability_scrims()
	_content_layer = Control.new()
	_content_layer.name = "ClassSelectContent"
	UiFactory.fill(_content_layer)
	add_child(_content_layer)
	_classes = AppRoot.config_service.first_playable_classes(true)
	get_viewport().size_changed.connect(_queue_rebuild)
	call_deferred("_build_initial_layout")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AppRoot.flow_controller.show_scene("main_menu")
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		_confirm_selected_class()
		accept_event()
	elif event.is_action_pressed("ui_left"):
		_select_class(_selected_index - 1)
		accept_event()
	elif event.is_action_pressed("ui_right"):
		_select_class(_selected_index + 1)
		accept_event()


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_layout")


func _build_initial_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_build_layout()
	_animate_entry()


func _rebuild_layout() -> void:
	_rebuild_queued = false
	_build_layout()


func _build_layout() -> void:
	if _content_layer == null:
		return
	_thumb_buttons.clear()
	for child in _content_layer.get_children():
		_content_layer.remove_child(child)
		child.queue_free()

	if _classes.is_empty():
		_classes = AppRoot.config_service.first_playable_classes(true)
	_selected_index = clampi(_selected_index, 0, max(0, _classes.size() - 1))

	var compact := _is_compact_layout()
	var short := _is_short_layout()
	var root := Control.new()
	root.name = "ClassSelectRoot"
	UiFactory.fill(root)
	_content_layer.add_child(root)

	_add_title(root, compact)
	_add_detail_panel(root, compact, short)
	_add_thumbnail_bar(root, compact, short)
	_add_nav_buttons(root, compact, short)
	_select_class(_selected_index, false)


func _add_readability_scrims() -> void:
	var dark := ColorRect.new()
	dark.name = "ReadabilityScrim"
	UiFactory.fill(dark)
	dark.color = Color(0.015, 0.012, 0.018, 0.10)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)

	var bottom := ColorRect.new()
	bottom.name = "BottomBandScrim"
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 0.68
	bottom.anchor_bottom = 1.0
	bottom.color = Color(0.02, 0.015, 0.02, 0.26)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)


func _add_title(root: Control, compact: bool) -> void:
	var title := Label.new()
	title.name = "ClassSelectTitle"
	title.text = "选择本局职业"
	title.add_theme_font_size_override("font_size", 28 if compact else 34)
	title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	title.anchor_left = 0.04
	title.anchor_top = 0.04
	title.anchor_right = 0.55
	title.anchor_bottom = 0.11
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	var scope := Label.new()
	scope.name = "ClassSelectScope"
	scope.text = "当前公开开局仅开放后端，其余职业可预览并保留为扩展占位。"
	scope.add_theme_font_size_override("font_size", 15 if compact else 17)
	scope.add_theme_color_override("font_color", Color(0.78, 0.90, 0.96, 0.88))
	scope.add_theme_constant_override("outline_size", 3)
	scope.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	scope.anchor_left = 0.04
	scope.anchor_top = 0.105
	scope.anchor_right = 0.72
	scope.anchor_bottom = 0.16
	scope.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scope)


func _add_detail_panel(root: Control, compact: bool, short: bool) -> void:
	var viewport_size := get_viewport_rect().size
	var panel_left := viewport_size.x * 0.045
	var panel_top := viewport_size.y * (0.22 if not short else 0.18)
	var panel_right := viewport_size.x * (0.48 if compact else 0.32)
	var panel_height := 260.0 if not compact else 250.0

	_detail_panel = PanelContainer.new()
	_detail_panel.name = "ClassDetailPanel"
	_detail_panel.anchor_left = 0.0
	_detail_panel.anchor_top = 0.0
	_detail_panel.anchor_right = 0.0
	_detail_panel.anchor_bottom = 0.0
	_detail_panel.offset_left = panel_left
	_detail_panel.offset_top = panel_top
	_detail_panel.offset_right = panel_right
	_detail_panel.offset_bottom = panel_top + panel_height
	root.add_child(_detail_panel)

	var box := VBoxContainer.new()
	box.name = "ClassDetailContent"
	box.add_theme_constant_override("separation", 7 if compact else 9)
	box.add_theme_constant_override("margin_left", 0)
	_detail_panel.add_child(box)

	_name_label = _detail_label("", 44 if not compact else 34, Color(1.0, 0.86, 0.34))
	_name_label.name = "ClassName"
	box.add_child(_name_label)

	var stat_row := HBoxContainer.new()
	stat_row.name = "ClassStatsRow"
	stat_row.add_theme_constant_override("separation", 18 if not compact else 10)
	box.add_child(stat_row)
	_spirit_label = _stat_chip("♥ 72/72", Color(1.0, 0.42, 0.45))
	_energy_label = _stat_chip("⚡ 3", Color(0.48, 0.92, 1.0))
	_difficulty_label = _stat_chip("难度 1", Color(1.0, 0.79, 0.34))
	stat_row.add_child(_spirit_label)
	stat_row.add_child(_energy_label)
	stat_row.add_child(_difficulty_label)

	_summary_label = _detail_label("", 17 if not compact else 14, Color(0.92, 0.95, 0.96))
	_summary_label.name = "ClassSummary"
	_summary_label.custom_minimum_size = Vector2(0, 34 if not compact else 28)
	box.add_child(_summary_label)

	_relic_label = _detail_label("", 15 if not compact else 13, Color(0.77, 0.88, 0.91))
	_relic_label.name = "ClassStarterRelic"
	box.add_child(_relic_label)

	_availability_label = _detail_label("", 17 if not compact else 14, Color(0.58, 0.95, 0.74))
	_availability_label.name = "ClassAvailability"
	box.add_child(_availability_label)

	_unlock_label = _detail_label("", 14 if not compact else 12, Color(0.72, 0.83, 0.86))
	_unlock_label.name = "ClassUnlockCondition"
	box.add_child(_unlock_label)

	_progress_label = _detail_label("", 14 if not compact else 12, Color(0.72, 0.83, 0.86))
	_progress_label.name = "ClassUnlockProgress"
	box.add_child(_progress_label)

func _add_thumbnail_bar(root: Control, compact: bool, short: bool) -> void:
	var holder := PanelContainer.new()
	holder.name = "ClassThumbnailBar"
	holder.anchor_left = 0.31 if not compact else 0.22
	holder.anchor_right = 0.73 if not compact else 0.79
	holder.anchor_top = 0.84 if not short else 0.76
	holder.anchor_bottom = 0.96 if not short else 0.94
	holder.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.24, 0.28, 0.16), Color(0.78, 0.88, 0.94, 0.14), 0))
	root.add_child(holder)

	var scroll := ScrollContainer.new()
	scroll.name = "ClassThumbnailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.add_child(scroll)

	_thumbnail_row = HBoxContainer.new()
	_thumbnail_row.name = "ClassThumbnailRow"
	_thumbnail_row.add_theme_constant_override("separation", 14 if not compact else 9)
	scroll.add_child(_thumbnail_row)

	for index in range(_classes.size()):
		_thumbnail_row.add_child(_thumbnail_button(index, compact))


func _add_nav_buttons(root: Control, compact: bool, short: bool) -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "←"
	back.tooltip_text = "返回主菜单"
	back.custom_minimum_size = Vector2(104, 72) if not compact else Vector2(78, 58)
	back.anchor_left = 0.03
	back.anchor_right = 0.03
	back.anchor_top = 0.84 if not short else 0.78
	back.anchor_bottom = 0.84 if not short else 0.78
	back.add_theme_font_size_override("font_size", 42 if not compact else 32)
	_style_button(back, Color(0.62, 0.12, 0.10, 0.90), Color(1.0, 0.42, 0.30, 0.78))
	UiMotion.bind_button(back, Color(1.0, 0.36, 0.32))
	back.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	root.add_child(back)

	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmClassButton"
	_confirm_button.text = "✓"
	_confirm_button.tooltip_text = "确认职业"
	_confirm_button.custom_minimum_size = Vector2(112, 78) if not compact else Vector2(84, 62)
	_confirm_button.anchor_left = 0.91
	_confirm_button.anchor_right = 0.91
	_confirm_button.anchor_top = 0.84 if not short else 0.78
	_confirm_button.anchor_bottom = 0.84 if not short else 0.78
	_confirm_button.add_theme_font_size_override("font_size", 42 if not compact else 32)
	UiMotion.bind_button(_confirm_button, Color(0.48, 0.90, 1.0))
	_confirm_button.pressed.connect(_confirm_selected_class)
	root.add_child(_confirm_button)


func _thumbnail_button(index: int, compact: bool) -> Button:
	var cls: Dictionary = _classes[index]
	var class_id := String(cls.get("id", ""))
	var button := Button.new()
	button.name = "ClassThumb_%s" % class_id
	button.custom_minimum_size = Vector2(78, 90) if not compact else Vector2(62, 76)
	button.tooltip_text = "%s：%s" % [cls.get("name", class_id), AppRoot.meta_service.class_availability_label(cls)]
	button.icon = load(String(CLASS_HEAD_ART.get(class_id, "")))
	button.expand_icon = true
	button.text = ""
	button.disabled = false
	button.pressed.connect(func(): _select_class(index))
	UiMotion.bind_button(button, _class_color(cls))
	_thumb_buttons.append(button)
	return button


func _select_class(index: int, animate := true) -> void:
	if _classes.is_empty():
		return
	_selected_index = posmod(index, _classes.size())
	var cls: Dictionary = _classes[_selected_index]
	var class_id := String(cls.get("id", ""))
	var accent := _class_color(cls)
	var playable := AppRoot.meta_service.is_class_playable(class_id)
	_background_rect.texture = _load_texture(_class_background_path(class_id))
	_update_panel_style(_detail_panel, accent, 0.92)
	_name_label.text = String(cls.get("name", class_id))
	_name_label.add_theme_color_override("font_color", accent.lightened(0.24))
	_spirit_label.text = "♥ %d/%d" % [PLAYER_SPIRIT, PLAYER_SPIRIT]
	_energy_label.text = "⚡ %d" % PLAYER_ENERGY
	_difficulty_label.text = "难度 %d" % int(cls.get("recommended_difficulty", 1))
	_summary_label.text = String(cls.get("summary", ""))
	_relic_label.text = "初始遗物：%s" % AppRoot.config_service.get_def("relics", String(cls.get("starter_relic_id", ""))).get("name", "无")
	_availability_label.text = "状态：%s" % AppRoot.meta_service.class_availability_label(cls)
	_availability_label.add_theme_color_override("font_color", _availability_color(cls))
	_unlock_label.text = "条件：%s" % AppRoot.meta_service.class_unlock_label(cls)
	_progress_label.text = "进度：%s" % AppRoot.meta_service.class_unlock_progress(cls)
	_confirm_button.disabled = false
	_confirm_button.text = "✓" if playable else "!"
	_confirm_button.tooltip_text = "开始后端单局" if playable else "该职业暂未开放"
	_style_button(_confirm_button, Color(0.10, 0.33, 0.42, 0.92) if playable else Color(0.24, 0.25, 0.28, 0.86), accent if playable else Color(0.62, 0.66, 0.70, 0.65))
	_update_thumbnails()
	if animate:
		UiMotion.fade_in(_detail_panel, 0.12, Vector2(-10, 0))
		UiMotion.fade_in(_background_rect, 0.12)


func _update_thumbnails() -> void:
	for index in range(_thumb_buttons.size()):
		var button: Button = _thumb_buttons[index]
		var cls: Dictionary = _classes[index]
		var selected := index == _selected_index
		var playable := AppRoot.meta_service.is_class_playable(String(cls.get("id", "")))
		var accent := _class_color(cls)
		var bg := Color(0.05, 0.07, 0.08, 0.86)
		var border := Color(0.45, 0.52, 0.56, 0.34)
		if selected:
			bg = Color(accent.r * 0.24, accent.g * 0.24, accent.b * 0.24, 0.92)
			border = accent
		button.modulate = Color(1, 1, 1, 1.0 if playable or selected else 0.46)
		_style_button(button, bg, border)


func _confirm_selected_class() -> void:
	if _classes.is_empty():
		return
	var cls: Dictionary = _classes[_selected_index]
	var class_id := String(cls.get("id", ""))
	if not AppRoot.meta_service.is_class_playable(class_id):
		if _confirm_button != null:
			UiMotion.shake(_confirm_button, 8.0, 0.12)
		if _detail_panel != null:
			UiMotion.shake(_detail_panel, 6.0, 0.12)
		return
	if _confirm_button != null:
		UiMotion.pop_in(_confirm_button, 0.18)
	AppRoot.reset_run()
	var run: Dictionary = AppRoot.run_session.create_new_run(class_id)
	if run.is_empty():
		return
	AppRoot.reward_service.prepare_initial_boosts(run)
	AppRoot.save_service.save_suspend(run, AppRoot.meta_service.meta_state)
	AppRoot.flow_controller.show_scene("initial_boost")


func _class_background_path(class_id: String) -> String:
	var bg_path := String(CLASS_CHARACTER_BG.get(class_id, ""))
	if ResourceLoader.exists(bg_path):
		return bg_path
	return String(CLASS_CHARACTER_BG.get("backend", ""))


func _load_texture(path: String):
	if path.is_empty():
		return null
	return load(path)


func _detail_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.70))
	return label


func _stat_chip(text: String, color: Color) -> Label:
	var label := _detail_label(text, 18, color)
	label.add_theme_font_size_override("font_size", 18)
	label.custom_minimum_size = Vector2(96, 28)
	return label


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


func _class_color(cls: Dictionary) -> Color:
	var color_text := String(cls.get("color", "#66D9EF"))
	if color_text.begins_with("#"):
		return Color.html(color_text)
	return Color(0.42, 0.82, 0.90)


func _panel_style(bg: Color, border: Color, radius := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style


func _update_panel_style(panel: PanelContainer, accent: Color, bg_alpha: float) -> void:
	if panel == null:
		return
	var bg := Color(0.035, 0.025, 0.027, bg_alpha)
	var border := Color(accent.r, accent.g, accent.b, 1.0)
	var style := _panel_style(bg, border, 7)
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)


func _style_button(button: Button, bg: Color, border: Color) -> void:
	var normal := _panel_style(bg, border, 5)
	var hover := _panel_style(bg.lightened(0.08), border.lightened(0.18), 5)
	var pressed := _panel_style(bg.darkened(0.08), border.lightened(0.28), 5)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88))


func _is_compact_layout() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.x < COMPACT_BREAKPOINT


func _is_short_layout() -> bool:
	return get_viewport_rect().size.y < SHORT_BREAKPOINT


func _animate_entry() -> void:
	for child in [_detail_panel, _thumbnail_row, _confirm_button]:
		if child is CanvasItem:
			UiMotion.fade_in(child, 0.18, Vector2(0, 14))
