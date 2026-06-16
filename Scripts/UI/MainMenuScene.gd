extends Control

const MAIN_BG := "res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png"
const COMPACT_BREAKPOINT := 1060.0
const SHORT_BREAKPOINT := 760.0
const BUILD_LABEL := "First Playable"
const ELEVATOR_STOPS := [
	{"floor": "1F", "name": "开放工位", "state": "当前入口"},
	{"floor": "6F", "name": "画饼主管", "state": "章末 Boss"},
	{"floor": "12F", "name": "变异 HR", "state": "中层封锁"},
	{"floor": "18F", "name": "总裁办公室", "state": "最终汇报"},
]
const CLASS_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
}
const MENU_ICONS := {
	"new_run": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-1.png",
	"continue": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-2.png",
	"meta": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-5.png",
	"quit": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-6.png",
}
const CLASS_RESOURCE_LABELS := {
	"backend": "服务 / 缓存",
	"frontend": "组件 / 样式层",
	"tester": "Bug / 用例",
	"algorithm": "算力 / 复杂度",
	"product_manager": "需求 / 优先级",
	"hr": "绩效 / 优化名单",
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
	_add_scrim(Color(0.02, 0.03, 0.04, 0.42))
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
		var alpha := 0.028 + 0.026 * (0.5 + 0.5 * sin(_ambient_time * 1.25 + float(index) * 0.8))
		line.color = Color(line.color.r, line.color.g, line.color.b, alpha)
	for index in range(_pulse_nodes.size()):
		var node = _pulse_nodes[index]
		if not is_instance_valid(node):
			continue
		var pulse := 0.82 + 0.18 * (0.5 + 0.5 * sin(_ambient_time * 1.6 + float(index) * 0.55))
		node.modulate = Color(1, 1, 1, pulse)

func _build_menu() -> void:
	if _content_layer == null:
		return
	_pulse_nodes.clear()
	for child in _content_layer.get_children():
		_content_layer.remove_child(child)
		child.queue_free()

	var compact := _is_compact_layout()
	var margin_size := 20 if compact else 44
	var scroll := ScrollContainer.new()
	UiFactory.fill(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_layer.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	scroll.add_child(margin)

	var root := UiFactory.vbox(24)
	root.add_theme_constant_override("separation", 16 if compact else 24)
	root.custom_minimum_size = _content_minimum_size(margin_size, compact)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	root.add_child(_top_bar(compact))

	var main: BoxContainer
	if compact:
		main = UiFactory.vbox(18)
	else:
		main = UiFactory.hbox(30)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)

	var hero := _hero_section(compact)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(hero)

	var menu := _menu_panel(compact)
	menu.custom_minimum_size = Vector2(0, 0) if compact else Vector2(380, 0)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_END
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(menu)

	root.add_child(_class_strip(compact))

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

func _content_minimum_size(margin_size: int, compact: bool) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var min_height := 680.0 if compact else 620.0
	var width := maxf(360.0, viewport_size.x - float(margin_size * 2) - 20.0)
	var height := maxf(min_height, viewport_size.y - float(margin_size * 2))
	return Vector2(width, height)

func _top_bar(compact := false) -> Control:
	var top: Control
	if compact:
		top = UiFactory.vbox(8)
	else:
		top = UiFactory.hbox(12)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var brand_row := UiFactory.hbox(12)
	brand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var brand := UiFactory.label("WITHGAI", 18, Color(0.90, 0.97, 1.0))
	brand.add_theme_constant_override("outline_size", 2)
	brand.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	brand_row.add_child(brand)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_row.add_child(spacer)

	brand_row.add_child(_status_chip(BUILD_LABEL))
	top.add_child(brand_row)

	var chip_row := UiFactory.hbox(8)
	chip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_row.add_child(_status_chip("%d 组值班" % _playable_class_count()))
	chip_row.add_child(_status_chip("三章爬楼"))
	chip_row.add_child(_status_chip("HR 解锁树占位"))
	top.add_child(chip_row)
	return top

func _hero_section(compact := false) -> Control:
	var hero := VBoxContainer.new()
	hero.add_theme_constant_override("separation", 16)
	hero.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := UiFactory.label("withgai", 60 if compact else 78, Color(0.95, 0.99, 1.0))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.05, 0.92))
	hero.add_child(title)

	var subtitle := UiFactory.label("写字楼爬楼卡牌肉鸽", 24 if compact else 30, Color(0.90, 0.95, 0.96))
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.05, 0.92))
	hero.add_child(subtitle)

	var copy := UiFactory.label("从开放工位一路打到 CEO 楼层。抽牌、加班、甩锅，然后活着下班。", 17 if compact else 20, Color(0.78, 0.86, 0.88))
	copy.custom_minimum_size = Vector2(0 if compact else 560, 0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(copy)

	var stats := UiFactory.hbox(10)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(_metric_chip(str(_table_count("cards")), "张卡牌"))
	stats.add_child(_metric_chip(str(_table_count("enemies")), "名敌人"))
	stats.add_child(_metric_chip("3", "章流程"))
	hero.add_child(stats)

	var dashboard: BoxContainer
	if compact:
		dashboard = UiFactory.vbox(12)
	else:
		dashboard = UiFactory.hbox(12)
	dashboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(dashboard)

	var board := _operations_board()
	board.custom_minimum_size = Vector2(0 if compact else 330, 142)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard.add_child(board)

	var elevator := _elevator_panel(compact)
	elevator.custom_minimum_size = Vector2(0 if compact else 230, 142)
	elevator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard.add_child(elevator)

	var save_info := _save_info_panel()
	save_info.custom_minimum_size = Vector2(0 if compact else 560, 104)
	save_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(save_info)
	return hero

func _menu_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.04, 0.06, 0.08, 0.86), Color(0.61, 0.79, 0.88, 0.62), 8)
	var pad := _pad(18 if compact else 24)
	panel.add_child(pad)

	var box := UiFactory.vbox(14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	box.add_child(UiFactory.label("异常办公入口", 26 if compact else 30, Color(0.95, 0.98, 1.0)))
	box.add_child(UiFactory.label("选择职业、恢复中断档，或先去工位树把椅子坐热。", 16, Color(0.72, 0.80, 0.82)))

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(1, 10)
	box.add_child(spacer_top)

	var new_button := _menu_button("新开一局", true, "new_run")
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

	var meta := AppRoot.meta_service.meta_state
	var currency := int(meta.get("owned_discomfort_currency", 0))
	var floor_record := int(meta.get("highest_floor_reached", 1))
	box.add_child(_record_row("窝囊费", str(currency)))
	box.add_child(_record_row("最高楼层", "%dF" % floor_record))
	box.add_child(_record_row("可出战职业", "%d/5" % _playable_class_count()))

	var quit_button := _menu_button("退出", false, "quit")
	quit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(quit_button)
	return panel

func _class_strip(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.03, 0.045, 0.06, 0.78), Color(0.45, 0.63, 0.72, 0.50), 8)
	var pad := _pad(14)
	panel.add_child(pad)

	var box := UiFactory.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var header: Control
	if compact:
		header = UiFactory.vbox(4)
	else:
		header = UiFactory.hbox(10)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(UiFactory.label("值班职业", 18, Color(0.88, 0.96, 0.98)))
	if not compact:
		var header_spacer := Control.new()
		header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(header_spacer)
	header.add_child(UiFactory.label("五职业可玩，HR 仅展示解锁树占位", 13, Color(0.58, 0.69, 0.72)))
	box.add_child(header)

	var row: Container
	if compact:
		var grid := GridContainer.new()
		grid.columns = 2 if get_viewport_rect().size.x >= 620.0 else 1
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		row = grid
	else:
		row = UiFactory.hbox(12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	for cls in AppRoot.config_service.first_playable_classes(true):
		row.add_child(_class_preview(_class_preview_item(cls), compact))
	return panel

func _class_preview(item: Dictionary, compact := false) -> PanelContainer:
	var accent: Color = item.get("color", Color.WHITE)
	var panel := _panel(Color(0.07, 0.09, 0.11, 0.84), accent.darkened(0.18), 7)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(240 if compact else 174, 126 if compact else 118)

	var pad := _pad(10)
	panel.add_child(pad)
	var row := UiFactory.hbox(10)
	pad.add_child(row)

	row.add_child(_class_portrait(item, accent))

	var text := UiFactory.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)

	var title_row := UiFactory.hbox(6)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(UiFactory.label(String(item.get("name", "")), 17, accent.lightened(0.18)))
	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)
	title_row.add_child(_mini_status(String(item.get("status", "")), accent))
	text.add_child(title_row)

	text.add_child(UiFactory.label(String(item.get("summary", "")), 13, Color(0.76, 0.84, 0.86)))
	var meta_row := UiFactory.hbox(6)
	meta_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.add_child(_mini_status(String(item.get("resource", "")), accent))
	meta_row.add_child(UiFactory.label("难度 %d / %d 牌" % [int(item.get("difficulty", 1)), int(item.get("card_count", 0))], 12, Color(0.54, 0.65, 0.68)))
	text.add_child(meta_row)
	return panel

func _save_info_panel() -> PanelContainer:
	var panel := _panel(Color(0.02, 0.04, 0.05, 0.72), Color(0.55, 0.72, 0.80, 0.48), 8)
	var pad := _pad(18)
	panel.add_child(pad)

	var box := UiFactory.vbox(6)
	pad.add_child(box)
	box.add_child(UiFactory.label("当前存档", 18, Color(0.86, 0.95, 0.98)))
	var line := "没有中断档"
	var detail := "新开一局会从 1F 前台重新排队。"
	var suspend := AppRoot.save_service.load_suspend() if AppRoot.save_service.has_suspend() else {}
	var run_state := _suspend_run_state(suspend)
	if not run_state.is_empty():
		var career_name := _class_name(String(run_state.get("selected_class_id", "")))
		var scene_tag := String(run_state.get("current_scene_tag", suspend.get("scene_tag", "map")))
		line = "%s / %dF / %s" % [career_name, int(run_state.get("current_floor", 1)), _scene_label(scene_tag)]
		detail = _format_save_time(int(suspend.get("timestamp", 0)))
	box.add_child(UiFactory.label(line, 16, Color(0.70, 0.80, 0.83)))
	box.add_child(UiFactory.label(detail, 14, Color(0.55, 0.65, 0.68)))
	return panel

func _operations_board() -> PanelContainer:
	var panel := _panel(Color(0.02, 0.035, 0.045, 0.70), Color(0.52, 0.68, 0.74, 0.42), 8)
	var pad := _pad(18)
	panel.add_child(pad)

	var box := UiFactory.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)
	box.add_child(UiFactory.label("夜班看板", 18, Color(0.86, 0.95, 0.98)))
	box.add_child(_board_row("今日路线", "普通冲突 -> 奖励 -> 楼层选择"))
	box.add_child(_board_row("晋升目标", "三章爬楼，抵达总裁办公室"))
	box.add_child(_board_row("当前规则", "五职业可玩，HR 档案只在局外展示"))
	return panel

func _elevator_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.025, 0.04, 0.052, 0.72), Color(0.56, 0.78, 0.84, 0.46), 8)
	var pad := _pad(14 if compact else 16)
	panel.add_child(pad)

	var box := UiFactory.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var header := UiFactory.hbox(8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(UiFactory.label("电梯大厅", 18, Color(0.86, 0.95, 0.98)))
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	var live := _status_chip("待命")
	_register_pulse(live)
	header.add_child(live)
	box.add_child(header)

	for index in range(ELEVATOR_STOPS.size()):
		var stop: Dictionary = ELEVATOR_STOPS[index]
		box.add_child(_elevator_stop_row(stop, index == 0))
	return panel

func _elevator_stop_row(stop: Dictionary, active: bool) -> Control:
	var row := UiFactory.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_floor_marker(active))

	var floor_label := UiFactory.label(String(stop.get("floor", "")), 13, Color(0.78, 0.95, 0.96) if active else Color(0.48, 0.62, 0.66))
	floor_label.custom_minimum_size = Vector2(34, 0)
	row.add_child(floor_label)

	var stop_name := UiFactory.label(String(stop.get("name", "")), 13, Color(0.84, 0.91, 0.92))
	stop_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stop_name)
	row.add_child(UiFactory.label(String(stop.get("state", "")), 12, Color(0.50, 0.63, 0.67)))
	return row

func _floor_marker(active: bool) -> PanelContainer:
	var color := Color(0.53, 0.98, 0.90, 0.94) if active else Color(0.22, 0.34, 0.37, 0.92)
	var panel := _panel(color, color.lightened(0.18), 4)
	panel.custom_minimum_size = Vector2(12, 12)
	if active:
		_register_pulse(panel)
	return panel

func _board_row(label_text: String, value_text: String) -> Control:
	var row := UiFactory.hbox(10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := UiFactory.label(label_text, 13, Color(0.50, 0.64, 0.68))
	label.custom_minimum_size = Vector2(78, 0)
	row.add_child(label)
	row.add_child(UiFactory.label(value_text, 14, Color(0.76, 0.86, 0.88)))
	return row

func _class_preview_item(cls: Dictionary) -> Dictionary:
	var class_id := String(cls.get("id", ""))
	var status := AppRoot.meta_service.class_availability_label(cls)
	if class_id == "hr":
		status = "解锁树占位"
	return {
		"id": class_id,
		"name": String(cls.get("name", class_id)),
		"summary": String(cls.get("summary", "")),
		"color": Color(String(cls.get("color", "#ffffff"))),
		"art": String(CLASS_ART.get(class_id, "")),
		"resource": String(CLASS_RESOURCE_LABELS.get(class_id, "职业资源")),
		"status": status,
		"difficulty": int(cls.get("recommended_difficulty", 1)),
		"card_count": _class_card_count(class_id),
	}

func _class_portrait(item: Dictionary, accent: Color) -> Control:
	var art_path := String(item.get("art", ""))
	if not art_path.is_empty():
		var portrait := UiFactory.texture(art_path, Vector2(58, 58))
		portrait.modulate = Color(1, 1, 1, 0.94)
		return portrait
	var fallback := _panel(accent.darkened(0.42), accent.lightened(0.12), 7)
	fallback.custom_minimum_size = Vector2(58, 58)
	var center := CenterContainer.new()
	fallback.add_child(center)
	var display_name := String(item.get("name", "?"))
	center.add_child(UiFactory.label(display_name.substr(0, 1), 24, Color(0.93, 0.98, 0.94)))
	return fallback

func _mini_status(text: String, accent: Color) -> PanelContainer:
	var chip := _panel(Color(accent.r, accent.g, accent.b, 0.13), Color(accent.r, accent.g, accent.b, 0.38), 5)
	var pad := _pad(5)
	chip.add_child(pad)
	var label := UiFactory.label(text, 11, accent.lightened(0.22))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad.add_child(label)
	return chip

func _menu_button(text: String, primary := false, icon_key := "") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	var icon := _load_menu_icon(icon_key)
	if icon != null:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var normal := _button_style(primary, false)
	var hover := _button_style(primary, true)
	var disabled := _button_style(false, false)
	disabled.bg_color = Color(0.12, 0.13, 0.14, 0.68)
	disabled.border_color = Color(0.32, 0.36, 0.38, 0.38)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.50, 0.56, 0.58))
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
	style.bg_color = Color(0.08, 0.12, 0.14, 0.92)
	style.border_color = Color(0.50, 0.67, 0.75, 0.55)
	if primary:
		style.bg_color = Color(0.12, 0.46, 0.48, 0.94)
		style.border_color = Color(0.58, 0.95, 0.92, 0.85)
	if hover:
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = style.border_color.lightened(0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style

func _record_row(label_text: String, value_text: String) -> Control:
	var row := UiFactory.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := UiFactory.label(label_text, 15, Color(0.64, 0.74, 0.77))
	row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(UiFactory.label(value_text, 17, Color(0.93, 0.98, 1.0)))
	return row

func _metric_chip(value: String, label_text: String) -> PanelContainer:
	var panel := _panel(Color(0.05, 0.075, 0.09, 0.76), Color(0.46, 0.62, 0.70, 0.42), 7)
	var pad := _pad(12)
	panel.add_child(pad)
	var box := UiFactory.vbox(2)
	pad.add_child(box)
	box.add_child(UiFactory.label(value, 24, Color(0.93, 0.99, 1.0)))
	box.add_child(UiFactory.label(label_text, 13, Color(0.65, 0.75, 0.78)))
	return panel

func _status_chip(text: String) -> PanelContainer:
	var chip := _panel(Color(0.04, 0.07, 0.08, 0.68), Color(0.50, 0.70, 0.78, 0.34), 6)
	var pad := _pad(8)
	chip.add_child(pad)
	pad.add_child(UiFactory.label(text, 13, Color(0.75, 0.86, 0.88)))
	return chip

func _table_count(table_name: String) -> int:
	if AppRoot.config_service == null:
		return 0
	return AppRoot.config_service.all_defs(table_name).size()

func _playable_class_count() -> int:
	var count := 0
	if AppRoot.config_service == null:
		return count
	for cls in AppRoot.config_service.first_playable_classes(false):
		if bool(cls.get("enabled_in_first_playable", false)):
			count += 1
	return count

func _class_card_count(class_id: String) -> int:
	if AppRoot.config_service == null or class_id == "hr":
		return 0
	return AppRoot.config_service.cards_for_class(class_id, true).size()

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

func _add_scrim(color: Color) -> void:
	var scrim := ColorRect.new()
	UiFactory.fill(scrim)
	scrim.color = color
	add_child(scrim)

func _add_atmosphere_overlay() -> void:
	var overlay := Control.new()
	UiFactory.fill(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_ambient_lines.clear()

	for index in range(8):
		var x := 0.09 + float(index) * 0.115
		var line := ColorRect.new()
		line.color = Color(0.60, 0.82, 0.88, 0.045)
		line.anchor_left = x
		line.anchor_right = x
		line.anchor_top = 0.0
		line.anchor_bottom = 1.0
		line.offset_right = 1.0
		overlay.add_child(line)
		_ambient_lines.append(line)

	for index in range(5):
		var y := 0.18 + float(index) * 0.15
		var line := ColorRect.new()
		line.color = Color(0.60, 0.82, 0.88, 0.04)
		line.anchor_left = 0.0
		line.anchor_right = 1.0
		line.anchor_top = y
		line.anchor_bottom = y
		line.offset_bottom = 1.0
		overlay.add_child(line)
		_ambient_lines.append(line)

	for index in range(4):
		var glow := ColorRect.new()
		glow.color = Color(0.20, 0.70, 0.74, 0.05)
		glow.anchor_left = 0.0
		glow.anchor_right = 1.0
		glow.anchor_top = 0.16 + float(index) * 0.20
		glow.anchor_bottom = glow.anchor_top
		glow.offset_bottom = 2.0
		overlay.add_child(glow)
		_ambient_lines.append(glow)

func _register_pulse(node: CanvasItem) -> void:
	_pulse_nodes.append(node)

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
