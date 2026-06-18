extends Control

const COMPACT_BREAKPOINT := 1040.0
const SHORT_BREAKPOINT := 760.0
const CLASS_CHARACTER_BG := {
	"backend": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_backend_character_bg_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_frontend_character_bg_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_tester_character_bg_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_algorithm_character_bg_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_product_manager_character_bg_v1/final.png",
	"hr": "res://Resources/Art/Generated/P0/backgrounds/ui_class_select_hr_character_bg_v1/final.png",
}

var _content_layer: Control
var _option_buttons: Array = []
var _rebuild_queued := false


func _ready() -> void:
	var app = _app_root()
	if app == null or app.run_session == null or app.flow_controller == null:
		return
	if app.run_session.run_state.is_empty():
		app.flow_controller.show_scene("main_menu")
		return
	UiFactory.fill(self)
	_add_background()
	_add_scrims()
	_content_layer = Control.new()
	_content_layer.name = "InitialBoostContent"
	UiFactory.fill(_content_layer)
	add_child(_content_layer)
	get_viewport().size_changed.connect(_queue_rebuild)
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _option_buttons.is_empty():
		_accept_boost(String(_option_buttons[0].get_meta("boost_id", "")))
		accept_event()


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	_build()


func _build() -> void:
	var app = _app_root()
	if app == null or app.reward_service == null or app.run_session == null:
		return
	_clear_content()
	var pending: Dictionary = app.reward_service.prepare_initial_boosts(app.run_session.run_state)
	var boost_ids: Array = pending.get("candidate_boost_ids", [])
	if boost_ids.is_empty():
		_go_map_without_boost()
		return
	var compact := _is_compact_layout()
	var short := _is_short_layout()
	var root := Control.new()
	root.name = "InitialBoostRoot"
	UiFactory.fill(root)
	_content_layer.add_child(root)
	_add_header(root, compact, short)
	_add_option_panel(root, boost_ids, compact, short)
	call_deferred("_animate_entry")


func _clear_content() -> void:
	if _content_layer == null:
		return
	_option_buttons.clear()
	for child in _content_layer.get_children():
		_content_layer.remove_child(child)
		child.queue_free()


func _add_background() -> void:
	var app = _app_root()
	if app == null or app.run_session == null:
		return
	var bg := TextureRect.new()
	bg.name = "InitialBoostBackground"
	UiFactory.fill(bg)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture = _load_texture(_class_background_path(String(app.run_session.run_state.get("selected_class_id", "backend"))))
	bg.modulate = Color(0.72, 0.80, 0.86, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _add_scrims() -> void:
	var dark := ColorRect.new()
	dark.name = "InitialBoostReadabilityScrim"
	UiFactory.fill(dark)
	dark.color = Color(0.015, 0.018, 0.022, 0.24)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)

	var band := ColorRect.new()
	band.name = "InitialBoostOptionBand"
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 0.54
	band.anchor_bottom = 1.0
	band.color = Color(0.0, 0.08, 0.12, 0.38)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)


func _add_header(root: Control, compact: bool, short: bool) -> void:
	var app = _app_root()
	if app == null or app.config_service == null or app.run_session == null:
		return
	var cls: Dictionary = app.config_service.get_def("classes", String(app.run_session.run_state.get("selected_class_id", "")))
	var title := Label.new()
	title.name = "InitialBoostHeader"
	title.text = "选择初始加强"
	title.add_theme_font_size_override("font_size", 28 if compact else 34)
	title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.82))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	title.anchor_left = 0.07
	title.anchor_top = 0.10 if not short else 0.06
	title.anchor_right = 0.55
	title.anchor_bottom = 0.18 if not short else 0.14
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "InitialBoostSubtitle"
	subtitle.text = "%s 开局前的最后准备" % String(cls.get("name", "本局"))
	subtitle.add_theme_font_size_override("font_size", 16 if compact else 18)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.92, 0.96, 0.92))
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.72))
	subtitle.anchor_left = 0.07
	subtitle.anchor_top = 0.18 if not short else 0.135
	subtitle.anchor_right = 0.62
	subtitle.anchor_bottom = 0.24 if not short else 0.19
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(subtitle)


func _add_option_panel(root: Control, boost_ids: Array, compact: bool, short: bool) -> void:
	var holder := VBoxContainer.new()
	holder.name = "InitialBoostOptionList"
	holder.add_theme_constant_override("separation", 8 if compact else 10)
	holder.anchor_left = 0.25 if not compact else 0.10
	holder.anchor_right = 0.76 if not compact else 0.91
	holder.anchor_top = 0.56 if not short else 0.48
	holder.anchor_bottom = 0.88 if not short else 0.88
	root.add_child(holder)
	for boost_id in boost_ids:
		var app = _app_root()
		if app == null or app.content_resolver == null:
			return
		var boost: Dictionary = app.content_resolver.initial_boost_def(String(boost_id))
		if boost.is_empty():
			continue
		holder.add_child(_boost_button(boost, compact))


func _boost_button(boost: Dictionary, compact: bool) -> Button:
	var button := Button.new()
	button.name = "InitialBoostButton_%s" % String(boost.get("id", ""))
	button.text = ""
	button.custom_minimum_size = Vector2(0, 90 if compact else 106)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("boost_id", String(boost.get("id", "")))
	_style_boost_button(button, Color(0.02, 0.20, 0.28, 0.76), Color(0.42, 0.86, 0.98, 0.38))
	UiMotion.bind_button(button, Color(0.40, 0.86, 0.98))
	button.pressed.connect(func(): _accept_boost(String(boost.get("id", ""))))
	_option_buttons.append(button)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14 if compact else 18)
	margin.add_child(row)

	var icon := UiFactory.texture(String(boost.get("art_path", "")), Vector2(58, 58) if compact else Vector2(70, 70))
	icon.name = "InitialBoostIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title := Label.new()
	title.name = "InitialBoostName"
	title.text = String(boost.get("name", ""))
	title.add_theme_font_size_override("font_size", 20 if compact else 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.26))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(title)

	var desc := Label.new()
	desc.name = "InitialBoostDescription"
	desc.text = String(boost.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14 if compact else 17)
	desc.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(desc)
	return button


func _accept_boost(boost_id: String) -> void:
	if boost_id.is_empty():
		return
	var app = _app_root()
	if app == null or app.reward_service == null or app.run_session == null or app.flow_controller == null:
		return
	if not app.reward_service.accept_initial_boost(app.run_session.run_state, boost_id):
		if not _option_buttons.is_empty():
			UiMotion.shake(_option_buttons[0], 7.0, 0.12)
		return
	UiMotion.scan_line(self, UiMotion.REWARD, 0.18)
	await get_tree().create_timer(0.12 if not UiMotion.reduce_motion() else 0.01).timeout
	app.flow_controller.show_scene("map")


func _go_map_without_boost() -> void:
	var app = _app_root()
	if app == null or app.run_session == null or app.flow_controller == null:
		return
	app.run_session.run_state["pending_initial_boost_state"] = {}
	app.run_session.run_state["current_scene_tag"] = "map"
	app.flow_controller.show_scene("map")


func _app_root():
	return get_tree().root.get_node_or_null("AppRoot")


func _class_background_path(class_id: String) -> String:
	var bg_path := String(CLASS_CHARACTER_BG.get(class_id, ""))
	if ResourceLoader.exists(bg_path):
		return bg_path
	return String(CLASS_CHARACTER_BG.get("backend", ""))


func _load_texture(path: String):
	if path.is_empty():
		return null
	return load(path)


func _style_boost_button(button: Button, bg: Color, border: Color) -> void:
	var normal := _panel_style(bg, border)
	var hover := _panel_style(bg.lightened(0.10), border.lightened(0.35))
	var pressed := _panel_style(bg.darkened(0.08), Color(1.0, 0.86, 0.36, 0.90))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)


func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _is_compact_layout() -> bool:
	return get_viewport_rect().size.x < COMPACT_BREAKPOINT


func _is_short_layout() -> bool:
	return get_viewport_rect().size.y < SHORT_BREAKPOINT


func _animate_entry() -> void:
	var header := find_child("InitialBoostHeader", true, false)
	if header != null:
		UiMotion.fade_in(header, 0.18, Vector2(0, 14))
	var delay := 0.0
	for button in _option_buttons:
		var captured = button
		var tween: Tween = button.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func(): UiMotion.pop_in(captured, 0.18))
		delay += 0.05
