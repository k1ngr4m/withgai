extends Control

const MAIN_BG := "res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png"
const COMPACT_BREAKPOINT := 900.0
const SHORT_BREAKPOINT := 620.0
const BUILD_LABEL := "首个可玩版本"
const MENU_WIDTH := 384.0
const DESKTOP_MARGIN := 44
const COMPACT_MARGIN := 22

const CLASS_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
}
const CLASS_SHORT_LABELS := {
	"backend": "后端",
	"frontend": "前端",
	"tester": "测试",
	"algorithm": "算法",
	"product_manager": "产品",
}
const MENU_ICONS := {
	"new_run": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-1.png",
	"continue": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-2.png",
	"meta": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-5.png",
	"quit": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-6.png",
}
const SCENE_LABELS := {
	"map": "楼层路线",
	"battle": "冲突处理中",
	"reward": "战后奖励",
	"shop": "自动贩卖机",
	"event": "随机事件",
	"rest": "茶水间休息",
	"run_result": "复盘结算",
	"class_select": "职业选择",
	"meta": "工位成长",
}

var _content_layer: Control
var _rebuild_queued := false
var _ambient_time := 0.0
var _ambient_lines: Array = []
var _pulse_nodes: Array = []


func _ready() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, MAIN_BG)
	_add_readability_scrims()
	_add_atmosphere_overlay()
	_content_layer = Control.new()
	UiFactory.fill(_content_layer)
	add_child(_content_layer)
	_build_menu()
	get_viewport().size_changed.connect(_queue_rebuild)
	set_process(true)


func _process(delta: float) -> void:
	_ambient_time += delta
	for index in range(_ambient_lines.size()):
		var line = _ambient_lines[index]
		if not is_instance_valid(line):
			continue
		var alpha := 0.024 + 0.024 * (0.5 + 0.5 * sin(_ambient_time * 1.18 + float(index) * 0.9))
		line.color = Color(line.color.r, line.color.g, line.color.b, alpha)
	for index in range(_pulse_nodes.size()):
		var node = _pulse_nodes[index]
		if not is_instance_valid(node):
			continue
		var pulse := 0.88 + 0.12 * (0.5 + 0.5 * sin(_ambient_time * 1.5 + float(index) * 0.65))
		node.modulate = Color(1, 1, 1, pulse)


func _build_menu() -> void:
	if _content_layer == null:
		return
	_pulse_nodes.clear()
	for child in _content_layer.get_children():
		_content_layer.remove_child(child)
		child.queue_free()

	if _is_compact_layout():
		_build_compact_menu()
	else:
		_build_desktop_menu()


func _build_desktop_menu() -> void:
	var margin := _root_margin(DESKTOP_MARGIN)
	_content_layer.add_child(margin)

	var root := UiFactory.hbox(36)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var left := UiFactory.vbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	left.add_child(_top_bar(false))
	var left_spacer := Control.new()
	left_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_spacer)
	left.add_child(_hero_block(false))
	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(1, 34)
	left.add_child(bottom_pad)

	var menu_wrap := CenterContainer.new()
	menu_wrap.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	menu_wrap.size_flags_horizontal = Control.SIZE_SHRINK_END
	menu_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(menu_wrap)

	var menu := _menu_panel(false)
	menu.custom_minimum_size = Vector2(MENU_WIDTH, 468)
	menu_wrap.add_child(menu)


func _build_compact_menu() -> void:
	var scroll := ScrollContainer.new()
	UiFactory.fill(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_layer.add_child(scroll)

	var margin := _root_margin(COMPACT_MARGIN)
	scroll.add_child(margin)

	var root := UiFactory.vbox(18)
	var viewport_size := get_viewport_rect().size
	root.custom_minimum_size = Vector2(maxf(320.0, viewport_size.x - float(COMPACT_MARGIN * 2)), 0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	root.add_child(_top_bar(true))
	root.add_child(_hero_block(true))

	var menu := _menu_panel(true)
	menu.custom_minimum_size = Vector2(0, 430)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(menu)


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_menu")


func _rebuild_menu() -> void:
	_rebuild_queued = false
	_build_menu()


func _is_compact_layout() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.x < COMPACT_BREAKPOINT or viewport_size.y < SHORT_BREAKPOINT


func _root_margin(margin_size: int) -> MarginContainer:
	var margin := MarginContainer.new()
	UiFactory.fill(margin)
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	return margin


func _top_bar(compact := false) -> Control:
	var row := UiFactory.hbox(10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(_status_chip(BUILD_LABEL))
	row.add_child(_status_chip("%d 组值班" % _playable_class_count()))
	if not compact:
		row.add_child(_status_chip("三章爬楼"))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	return row


func _hero_block(compact := false) -> Control:
	var box := UiFactory.vbox(14 if compact else 16)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := _label("withgai", 56 if compact else 64, Color(0.96, 0.99, 1.0))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.94))
	title.custom_minimum_size = Vector2(320, 70 if compact else 82)
	box.add_child(title)

	var subtitle := _label("写字楼爬楼卡牌肉鸽", 21 if compact else 22, Color(0.90, 0.96, 0.97))
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.94))
	subtitle.custom_minimum_size = Vector2(320, 30)
	box.add_child(subtitle)

	var copy := _label("抽牌、加班、甩锅，一路爬到总裁办公室。", 16 if compact else 17, Color(0.74, 0.84, 0.86))
	copy.custom_minimum_size = Vector2(320, 28)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(copy)

	var crew := _crew_strip(compact)
	crew.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(crew)
	return box


func _menu_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.025, 0.040, 0.050, 0.91), Color(0.53, 0.83, 0.86, 0.68), 8)
	var pad := _pad(20 if compact else 24)
	panel.add_child(pad)

	var box := UiFactory.vbox(13)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var title := _label("今晚从哪开工？", 25 if compact else 27, Color(0.95, 0.99, 1.0))
	title.custom_minimum_size = Vector2(260, 34)
	box.add_child(title)

	var copy := _label("选职业、接着打，或者先去工位树垫点底气。", 14, Color(0.67, 0.78, 0.80))
	copy.custom_minimum_size = Vector2(260, 44)
	box.add_child(copy)

	var button_gap := Control.new()
	button_gap.custom_minimum_size = Vector2(1, 4)
	box.add_child(button_gap)

	var new_button := _menu_button("开始爬楼", true, "new_run")
	new_button.tooltip_text = "进入职业选择界面"
	new_button.pressed.connect(func(): AppRoot.flow_controller.show_scene("class_select"))
	box.add_child(new_button)
	new_button.call_deferred("grab_focus")

	var continue_button := _menu_button("继续中断档", false, "continue")
	continue_button.disabled = not _has_valid_suspend()
	continue_button.tooltip_text = "从最近一次中断的楼层继续"
	continue_button.pressed.connect(_continue_run)
	box.add_child(continue_button)

	var meta_button := _menu_button("工位成长", false, "meta")
	meta_button.tooltip_text = "打开局外成长和职业解锁树"
	meta_button.pressed.connect(func(): AppRoot.flow_controller.show_scene("meta"))
	box.add_child(meta_button)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)

	box.add_child(_save_status_card())

	var quit_button := _menu_button("退出游戏", false, "quit")
	quit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(quit_button)
	return panel


func _save_status_card() -> PanelContainer:
	var panel := _panel(Color(0.03, 0.055, 0.065, 0.78), Color(0.38, 0.62, 0.68, 0.46), 7)
	var pad := _pad(14)
	panel.add_child(pad)

	var box := UiFactory.vbox(5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var meta := AppRoot.meta_service.meta_state
	var currency := int(meta.get("owned_discomfort_currency", 0))
	var floor_record := int(meta.get("highest_floor_reached", 1))
	box.add_child(_label("当前存档", 16, Color(0.86, 0.95, 0.98)))

	var line := "没有中断档"
	var detail := "新开一局会从 1F 前台重新排队。"
	var suspend := AppRoot.save_service.load_suspend() if AppRoot.save_service.has_suspend() else {}
	var run_state := _suspend_run_state(suspend)
	if not run_state.is_empty():
		var career_name := _class_name(String(run_state.get("selected_class_id", "")))
		var scene_tag := String(run_state.get("current_scene_tag", suspend.get("scene_tag", "map")))
		line = "%s / %dF / %s" % [career_name, int(run_state.get("current_floor", 1)), _scene_label(scene_tag)]
		detail = _format_save_time(int(suspend.get("timestamp", 0)))

	var line_label := _label(line, 14, Color(0.73, 0.84, 0.86))
	line_label.custom_minimum_size = Vector2(250, 22)
	box.add_child(line_label)
	var detail_label := _label(detail, 12, Color(0.56, 0.67, 0.70))
	detail_label.custom_minimum_size = Vector2(250, 20)
	box.add_child(detail_label)
	box.add_child(_record_row("窝囊费", str(currency)))
	box.add_child(_record_row("最高楼层", "%dF" % floor_record))
	return panel


func _crew_strip(compact := false) -> Control:
	var row: Container
	if compact:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		row = grid
	else:
		row = UiFactory.hbox(10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for cls in AppRoot.config_service.first_playable_classes(false):
		if bool(cls.get("enabled_in_first_playable", false)):
			row.add_child(_class_pill(_class_preview_item(cls), compact))
	return row


func _class_pill(item: Dictionary, compact := false) -> PanelContainer:
	var accent: Color = item.get("color", Color.WHITE)
	var panel := _panel(Color(0.035, 0.055, 0.065, 0.78), Color(accent.r, accent.g, accent.b, 0.50), 7)
	panel.custom_minimum_size = Vector2(178 if compact else 126, 54)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN

	var pad := _pad(7)
	panel.add_child(pad)
	var row := UiFactory.hbox(8)
	pad.add_child(row)

	var portrait := _class_portrait(item, accent)
	portrait.custom_minimum_size = Vector2(38, 38)
	row.add_child(portrait)

	var name_label := _label(String(item.get("short_name", item.get("name", ""))), 13, Color(0.92, 0.98, 1.0))
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.custom_minimum_size = Vector2(74 if compact else 54, 34)
	name_label.clip_text = true
	row.add_child(name_label)
	return panel


func _class_preview_item(cls: Dictionary) -> Dictionary:
	var class_id := String(cls.get("id", ""))
	return {
		"id": class_id,
		"name": String(cls.get("name", class_id)),
		"short_name": String(CLASS_SHORT_LABELS.get(class_id, cls.get("name", class_id))),
		"color": Color(String(cls.get("color", "#ffffff"))),
		"art": String(CLASS_ART.get(class_id, "")),
	}


func _class_portrait(item: Dictionary, accent: Color) -> Control:
	var art_path := String(item.get("art", ""))
	if not art_path.is_empty():
		var portrait := UiFactory.texture(art_path, Vector2(38, 38))
		portrait.modulate = Color(1, 1, 1, 0.96)
		return portrait
	var fallback := _panel(accent.darkened(0.42), accent.lightened(0.12), 7)
	fallback.custom_minimum_size = Vector2(38, 38)
	var center := CenterContainer.new()
	fallback.add_child(center)
	var display_name := String(item.get("name", "?"))
	center.add_child(_label(display_name.substr(0, 1), 18, Color(0.93, 0.98, 0.94)))
	return fallback


func _menu_button(text: String, primary := false, icon_key := "") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.55, 0.57))
	button.add_theme_color_override("icon_normal_color", Color(0.92, 0.98, 1.0))
	button.add_theme_color_override("icon_disabled_color", Color(0.48, 0.55, 0.57))

	var icon := _load_menu_icon(icon_key)
	if icon != null:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var normal := _button_style(primary, false)
	var hover := _button_style(primary, true)
	var disabled := _button_style(false, false)
	disabled.bg_color = Color(0.10, 0.12, 0.13, 0.70)
	disabled.border_color = Color(0.30, 0.36, 0.38, 0.42)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	return button


func _load_menu_icon(icon_key: String) -> Texture2D:
	var icon_path := String(MENU_ICONS.get(icon_key, ""))
	if icon_path.is_empty():
		return null
	var source_texture := load(icon_path) as Texture2D
	if source_texture == null:
		return null
	var image := source_texture.get_image()
	if image == null:
		return source_texture
	image.resize(30, 30, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _button_style(primary: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.105, 0.120, 0.94)
	style.border_color = Color(0.44, 0.62, 0.68, 0.60)
	if primary:
		style.bg_color = Color(0.09, 0.45, 0.46, 0.96)
		style.border_color = Color(0.56, 0.96, 0.91, 0.88)
	if hover:
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = style.border_color.lightened(0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


func _record_row(label_text: String, value_text: String) -> Control:
	var label := _label("%s  %s" % [label_text, value_text], 13, Color(0.80, 0.91, 0.93))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2(250, 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _status_chip(text: String) -> PanelContainer:
	var chip := _panel(Color(0.04, 0.07, 0.08, 0.70), Color(0.50, 0.72, 0.78, 0.42), 6)
	var pad := _pad(8)
	chip.add_child(pad)
	var label := _label(text, 12, Color(0.75, 0.86, 0.88))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2(maxf(62.0, float(text.length()) * 14.0), 18)
	label.clip_text = true
	pad.add_child(label)
	return chip


func _label(text: String, font_size := 18, color := Color.WHITE) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _playable_class_count() -> int:
	var count := 0
	if AppRoot.config_service == null:
		return count
	for cls in AppRoot.config_service.first_playable_classes(false):
		if bool(cls.get("enabled_in_first_playable", false)):
			count += 1
	return count


func _has_valid_suspend() -> bool:
	return not _suspend_run_state().is_empty()


func _suspend_run_state(save_state: Dictionary = {}) -> Dictionary:
	if save_state.is_empty():
		if not AppRoot.save_service.has_suspend():
			return {}
		save_state = AppRoot.save_service.load_suspend()
	var run_state = save_state.get("serialized_run_state", {})
	return run_state if typeof(run_state) == TYPE_DICTIONARY else {}


func _class_name(class_id: String) -> String:
	var cls: Dictionary = AppRoot.config_service.get_def("classes", class_id)
	return String(cls.get("name", class_id if not class_id.is_empty() else "未知职业"))


func _scene_label(scene_tag: String) -> String:
	return String(SCENE_LABELS.get(scene_tag, scene_tag))


func _format_save_time(timestamp: int) -> String:
	if timestamp <= 0:
		return "保存时间未知"
	var dt := Time.get_datetime_dict_from_unix_time(timestamp)
	return "保存于 %04d-%02d-%02d %02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
	]


func _add_readability_scrims() -> void:
	var base := ColorRect.new()
	UiFactory.fill(base)
	base.color = Color(0.01, 0.015, 0.018, 0.28)
	add_child(base)

	var bottom := ColorRect.new()
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 0.48
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 0
	bottom.offset_right = 0
	bottom.offset_top = 0
	bottom.offset_bottom = 0
	bottom.color = Color(0.01, 0.018, 0.022, 0.42)
	add_child(bottom)

	var right := ColorRect.new()
	right.anchor_left = 0.64
	right.anchor_right = 1.0
	right.anchor_top = 0.0
	right.anchor_bottom = 1.0
	right.offset_left = 0
	right.offset_right = 0
	right.offset_top = 0
	right.offset_bottom = 0
	right.color = Color(0.01, 0.018, 0.022, 0.34)
	add_child(right)


func _add_atmosphere_overlay() -> void:
	var overlay := Control.new()
	UiFactory.fill(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_ambient_lines.clear()

	for index in range(6):
		var x := 0.12 + float(index) * 0.15
		var line := ColorRect.new()
		line.color = Color(0.60, 0.82, 0.88, 0.034)
		line.anchor_left = x
		line.anchor_right = x
		line.anchor_top = 0.0
		line.anchor_bottom = 1.0
		line.offset_right = 1.0
		overlay.add_child(line)
		_ambient_lines.append(line)

	for index in range(4):
		var y := 0.22 + float(index) * 0.18
		var line := ColorRect.new()
		line.color = Color(0.60, 0.82, 0.88, 0.032)
		line.anchor_left = 0.0
		line.anchor_right = 1.0
		line.anchor_top = y
		line.anchor_bottom = y
		line.offset_bottom = 1.0
		overlay.add_child(line)
		_ambient_lines.append(line)


func _panel(bg_color: Color, border_color: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _pad(margin_size: int) -> MarginContainer:
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", margin_size)
	pad.add_theme_constant_override("margin_right", margin_size)
	pad.add_theme_constant_override("margin_top", margin_size)
	pad.add_theme_constant_override("margin_bottom", margin_size)
	return pad


func _continue_run() -> void:
	if AppRoot.run_session.restore_from_suspend(AppRoot.save_service.load_suspend()):
		var tag: String = String(AppRoot.run_session.run_state.get("current_scene_tag", "map"))
		if tag == "battle" and not AppRoot.battle_service.restore_battle(AppRoot.run_session.run_state):
			tag = "map"
			AppRoot.run_session.run_state["current_scene_tag"] = "map"
		AppRoot.flow_controller.show_scene(tag)
