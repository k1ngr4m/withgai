extends Control

const MAP_ICON_PATHS := {
	"normal_battle": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-1.png",
	"elite_battle": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-2.png",
	"shop": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-5.png",
	"event": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-4.png",
	"rest": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-3.png",
	"boss": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-7.png",
}
const LEGEND_NODE_TYPES := ["normal_battle", "elite_battle", "shop", "event", "rest", "boss"]
const TREE_CANVAS_SIZE := Vector2(940, 700)
const TREE_PANEL_PADDING := 20
const TREE_NODE_SIZE := Vector2(86, 86)
const TREE_X_POSITIONS := [210.0, 470.0, 730.0]
const TREE_BOTTOM_Y := 606.0
const TREE_FLOOR_GAP := 112.0

var _selected_node_id := ""
var _node_buttons := {}
var _node_detail_box: VBoxContainer
var _enter_button: Button
var _map_tree_canvas: Control


func _ready() -> void:
	_build()


func _build() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_map_floor_navigation_v1.png")
	_add_background_mask()
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 20)
	var main := UiFactory.vbox(10)
	margin.add_child(main)
	var cls: Dictionary = AppRoot.config_service.get_def("classes", run.get("selected_class_id", ""))
	var header := UiFactory.label("第 %d 章 | 当前楼层 %d | %s | 精神 %d/%d | 绩效点 %d" % [
		int(run.get("current_chapter", 1)),
		int(run.get("current_floor", 1)),
		cls.get("name", ""),
		int(run.get("player_state", {}).get("current_spirit", 0)),
		int(run.get("player_state", {}).get("max_spirit", 0)),
		int(run.get("currency_perf_points", 0)),
	], 24)
	header.name = "ChapterHeader"
	main.add_child(header)

	var body := UiFactory.hbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(body)

	var graph := _map_tree_panel(run)
	graph.name = "MapGraphPanel"
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(graph)

	var side := UiFactory.vbox(10)
	side.custom_minimum_size = Vector2(320, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	side.add_child(_map_legend_panel())
	side.add_child(_floor_info_panel(run, cls))
	side.add_child(_node_detail_panel())

	var available: Array = run.get("map_state", {}).get("available_next_nodes", [])
	var visited: Array = run.get("visited_node_ids", [])
	_selected_node_id = _default_selected_node(available, visited)
	_build_map_tree(run, available, visited)

	var bottom := UiFactory.hbox(8)
	main.add_child(bottom)
	_enter_button = UiFactory.button("进入选中节点")
	_enter_button.name = "ResumeButton"
	_enter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enter_button.disabled = true
	_enter_button.pressed.connect(_enter_selected_node)
	bottom.add_child(_enter_button)
	var save := UiFactory.button("保存")
	save.name = "SaveButton"
	save.pressed.connect(func(): AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state))
	bottom.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "MainMenuButton"
	menu.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	bottom.add_child(menu)
	_refresh_node_details()
	call_deferred("_animate_entry")


func _add_background_mask() -> void:
	var mask := ColorRect.new()
	mask.name = "MapBackgroundMask"
	UiFactory.fill(mask)
	mask.color = Color(0.010, 0.016, 0.024, 0.66)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mask)


func _map_tree_panel(_run: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "MapTreePanel"
	panel.custom_minimum_size = TREE_CANVAS_SIZE + Vector2(TREE_PANEL_PADDING * 2, TREE_PANEL_PADDING * 2)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.020, 0.028, 0.18), Color(0.42, 0.70, 0.76, 0.22), 8, 1))
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)
	var canvas := Control.new()
	canvas.name = "MapTreeCanvas"
	canvas.custom_minimum_size = TREE_CANVAS_SIZE
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_tree_canvas = canvas
	center.add_child(canvas)
	return panel


func _build_map_tree(run: Dictionary, available: Array, visited: Array) -> void:
	if _map_tree_canvas == null:
		return
	_node_buttons.clear()
	var floors: Array = run.get("map_state", {}).get("floors", [])
	var graph: Dictionary = run.get("map_state", {}).get("node_graph", {})
	if graph.is_empty():
		graph = AppRoot.map_service.call("_ensure_node_graph", run)
	_draw_tree_connections(floors, graph, visited)
	for layer in floors:
		for node in layer:
			var node_id := String(node.get("id", ""))
			var position := _tree_node_position(node)
			var b := _map_node_button(node, available.has(node_id), visited.has(node_id), node_id == _selected_node_id)
			b.position = position - TREE_NODE_SIZE * 0.5
			b.pressed.connect(func(): _select_node(node_id))
			_node_buttons[node_id] = b
			_map_tree_canvas.add_child(b)


func _draw_tree_connections(floors: Array, graph: Dictionary, visited: Array) -> void:
	for layer in floors:
		for node in layer:
			var from_id := String(node.get("id", ""))
			var from_pos := _tree_node_position(node)
			for next_id_value in node.get("next_ids", []):
				var next_id := String(next_id_value)
				if not graph.has(next_id):
					continue
				var next_node: Dictionary = graph.get(next_id, {})
				var to_pos := _tree_node_position(next_node)
				_add_dashed_route(from_pos, to_pos, Color(0.0, 0.0, 0.0, 0.42), 7.0, -3, 16.0, 10.0)
				_add_dashed_route(from_pos, to_pos, _route_line_color(from_id, next_id, visited), _route_line_width(from_id, next_id, visited), -2, 15.0, 11.0)


func _add_dashed_route(from_pos: Vector2, to_pos: Vector2, color: Color, width: float, z_index: int, dash_length: float, gap_length: float) -> void:
	var delta := to_pos - from_pos
	var distance := delta.length()
	if distance <= 0.1:
		return
	var direction := delta / distance
	var normal := Vector2(-direction.y, direction.x)
	var cursor := 0.0
	var segment_index := 0
	while cursor < distance:
		var end_distance: float = minf(cursor + dash_length, distance)
		var mid_ratio: float = (cursor + end_distance) / maxf(distance * 2.0, 0.1)
		var wobble := sin(mid_ratio * TAU * 1.7 + float(segment_index) * 0.45) * 2.0
		var start := from_pos + direction * cursor + normal * wobble
		var end := from_pos + direction * end_distance - normal * wobble * 0.35
		var line := Line2D.new()
		line.name = "MapRouteDash"
		line.z_index = z_index
		line.width = width
		line.default_color = color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.points = PackedVector2Array([start, end])
		_map_tree_canvas.add_child(line)
		cursor += dash_length + gap_length
		segment_index += 1


func _route_line_color(from_id: String, to_id: String, visited: Array) -> Color:
	if visited.has(from_id):
		return Color(0.76, 0.94, 1.0, 0.72)
	if _selected_node_id == from_id or _selected_node_id == to_id:
		return Color(0.62, 0.95, 1.0, 0.86)
	return Color(0.42, 0.62, 0.72, 0.50)


func _route_line_width(from_id: String, to_id: String, visited: Array) -> float:
	if visited.has(from_id) or _selected_node_id == from_id or _selected_node_id == to_id:
		return 5.5
	return 4.0


func _tree_node_position(node: Dictionary) -> Vector2:
	var local_floor := int(node.get("local_floor", max(0, int(node.get("floor", 1)) - 1)))
	var layer_index := int(node.get("index", 1))
	if local_floor == 5:
		layer_index = 1
	var x := float(TREE_X_POSITIONS[clampi(layer_index, 0, TREE_X_POSITIONS.size() - 1)])
	var y := TREE_BOTTOM_Y - float(local_floor) * TREE_FLOOR_GAP
	return Vector2(x, y)


func _map_node_button(node: Dictionary, available: bool, visited: bool, selected: bool) -> Button:
	var node_type := String(node.get("node_type", ""))
	var button := Button.new()
	button.name = "MapNodeButton%s" % String(node.get("id", "")).capitalize()
	button.custom_minimum_size = TREE_NODE_SIZE
	button.size = TREE_NODE_SIZE
	button.text = "%dF%s" % [int(node.get("floor", 0)), "\n✓" if visited else ""]
	button.icon = load(_node_icon_path(node_type))
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.tooltip_text = "%dF %s" % [int(node.get("floor", 0)), UiFactory.type_name(node_type)]
	button.disabled = false
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.90, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.80, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _node_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0))
	button.add_theme_stylebox_override("hover", _node_style(Color(0.04, 0.10, 0.11, 0.26), Color(0.52, 0.90, 0.98, 0.72), 2))
	button.add_theme_stylebox_override("pressed", _node_style(Color(0.03, 0.08, 0.10, 0.34), Color(0.72, 1.0, 1.0, 0.92), 2))
	button.add_theme_stylebox_override("disabled", _node_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0))
	if visited:
		button.modulate = Color(0.58, 0.70, 0.76, 0.70)
	elif available:
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		button.add_theme_stylebox_override("normal", _node_style(Color(0.03, 0.09, 0.10, 0.22), Color(0.55, 0.96, 1.0, 0.52), 1))
	else:
		button.modulate = Color(0.46, 0.52, 0.56, 0.58)
	if selected:
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		button.pivot_offset = TREE_NODE_SIZE * 0.5
		button.scale = Vector2(1.12, 1.12)
		button.z_index = 5
		button.add_theme_color_override("font_color", Color(0.72, 0.98, 1.0))
		button.add_theme_stylebox_override("normal", _node_style(Color(0.02, 0.08, 0.09, 0.18), Color(0.86, 1.0, 1.0, 0.96), 4))
		button.add_theme_stylebox_override("hover", _node_style(Color(0.02, 0.10, 0.12, 0.28), Color(0.86, 1.0, 1.0, 1.0), 4))
	return button


func _node_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	return _panel_style(bg_color, border_color, 43, border_width)


func _panel_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _node_icon_path(node_type: String) -> String:
	return String(MAP_ICON_PATHS.get(node_type, MAP_ICON_PATHS.get("normal_battle", "")))


func _map_legend_panel() -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "MapLegendPanel"
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(pad)
	var box := UiFactory.vbox(8)
	pad.add_child(box)
	box.add_child(UiFactory.label("图例", 22))
	for node_type in LEGEND_NODE_TYPES:
		box.add_child(_legend_row(node_type))
	return panel


func _legend_row(node_type: String) -> HBoxContainer:
	var row := UiFactory.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := UiFactory.texture(_node_icon_path(node_type), Vector2(30, 30))
	icon.modulate = Color(0.88, 0.98, 1.0, 0.92)
	row.add_child(icon)
	var label := UiFactory.label(UiFactory.type_name(node_type), 15, Color(0.82, 0.94, 0.96))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _floor_info_panel(run: Dictionary, cls: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "FloorInfoPanel"
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(pad)
	var box := UiFactory.vbox(6)
	pad.add_child(box)
	box.add_child(UiFactory.label("路线状态", 20))
	box.add_child(UiFactory.label("职业：%s" % String(cls.get("name", "")), 14, Color(0.76, 0.90, 0.92)))
	box.add_child(UiFactory.label("牌组：%d 张" % int(run.get("deck_state", {}).get("master_deck", []).size()), 14, Color(0.76, 0.90, 0.92)))
	box.add_child(UiFactory.label("遗物：%d 件" % int(run.get("owned_relic_ids", []).size()), 14, Color(0.76, 0.90, 0.92)))
	box.add_child(UiFactory.label("可选节点：%d" % int(run.get("map_state", {}).get("available_next_nodes", []).size()), 14, Color(0.76, 0.90, 0.92)))
	return panel


func _node_detail_panel() -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "NodeDetailPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(pad)
	_node_detail_box = UiFactory.vbox(8)
	_node_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_node_detail_box)
	return panel


func _select_node(node_id: String) -> void:
	_selected_node_id = node_id
	_rebuild_map_tree()
	_refresh_node_details()
	var button = _node_buttons.get(node_id)
	if button is Control:
		UiMotion.flash_modulate(button, UiMotion.SERVICE, 0.16)


func _rebuild_map_tree() -> void:
	if _map_tree_canvas == null:
		return
	for child in _map_tree_canvas.get_children():
		child.queue_free()
	var run := AppRoot.run_session.run_state
	var available: Array = run.get("map_state", {}).get("available_next_nodes", [])
	var visited: Array = run.get("visited_node_ids", [])
	_build_map_tree(run, available, visited)


func _refresh_node_buttons() -> void:
	var run := AppRoot.run_session.run_state
	var visited: Array = run.get("visited_node_ids", [])
	for node_id in _node_buttons.keys():
		var button: Button = _node_buttons[node_id]
		if not is_instance_valid(button):
			continue
		var node := AppRoot.map_service.find_node(run, String(node_id))
		if node.is_empty():
			continue
		button.text = _node_button_text(node, String(node_id) == _selected_node_id, visited.has(node_id))


func _refresh_node_details() -> void:
	if _node_detail_box == null:
		return
	for child in _node_detail_box.get_children():
		_node_detail_box.remove_child(child)
		if child == _enter_button:
			_enter_button = null
		child.queue_free()
	var run := AppRoot.run_session.run_state
	var available: Array = run.get("map_state", {}).get("available_next_nodes", [])
	var visited: Array = run.get("visited_node_ids", [])
	var node := AppRoot.map_service.find_node(run, _selected_node_id)
	if node.is_empty():
		_node_detail_box.add_child(UiFactory.label("选择一个可前进节点", 20))
		_node_detail_box.add_child(UiFactory.label("左侧亮起的楼层节点可以进入。", 14, Color(0.74, 0.86, 0.88)))
		_set_enter_button_state(false, "进入选中节点")
		return

	var node_type := String(node.get("node_type", ""))
	var can_enter := available.has(_selected_node_id) and not visited.has(_selected_node_id)
	_node_detail_box.add_child(UiFactory.label("%dF  %s" % [int(node.get("floor", 0)), UiFactory.type_name(node_type)], 22))
	_node_detail_box.add_child(UiFactory.label(_node_flavor(node_type), 14, Color(0.78, 0.90, 0.92)))
	_node_detail_box.add_child(UiFactory.label(_node_reward_hint(node_type), 14, Color(0.92, 0.84, 0.58)))
	_node_detail_box.add_child(UiFactory.label("后续路线：%d 条" % int(node.get("next_ids", []).size()), 13, Color(0.65, 0.78, 0.80)))
	if can_enter:
		_set_enter_button_state(true, "进入 %dF %s" % [int(node.get("floor", 0)), UiFactory.type_name(node_type)])
	elif visited.has(_selected_node_id):
		_set_enter_button_state(false, "该节点已完成")
	else:
		_set_enter_button_state(false, "路线尚未开放")


func _set_enter_button_state(enabled: bool, label_text: String) -> void:
	if _enter_button == null or not is_instance_valid(_enter_button):
		_enter_button = UiFactory.button(label_text)
		_enter_button.name = "ResumeButton"
		_enter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_enter_button.pressed.connect(_enter_selected_node)
		_node_detail_box.add_child(_enter_button)
	else:
		if _enter_button.get_parent() == null:
			_node_detail_box.add_child(_enter_button)
	_enter_button.text = label_text
	_enter_button.disabled = not enabled


func _enter_selected_node() -> void:
	_enter_node(_selected_node_id)


func _default_selected_node(available: Array, visited: Array) -> String:
	for node_id in available:
		if not visited.has(node_id):
			return String(node_id)
	return ""


func _node_button_text(node: Dictionary, selected: bool, visited: bool) -> String:
	var lines := [
		"%dF" % int(node.get("floor", 0)),
		UiFactory.type_name(String(node.get("node_type", ""))),
	]
	if visited:
		lines.append("已完成")
	elif selected:
		lines.append("待进入")
	return "\n".join(lines)


func _node_flavor(node_type: String) -> String:
	match node_type:
		"normal_battle":
			return "跨部门冲突，适合用后端 starter deck 继续堆服务和缓存。"
		"elite_battle":
			return "高压插队需求，胜利后会记录精英里程碑并给出更好的回报。"
		"boss":
			return "楼层守门人，击败后推进章节；顶层 Boss 胜利会进入结算。"
		"shop":
			return "自动贩卖机，可以买牌、买遗物、删牌或刷新货架。"
		"event":
			return "随机办公室事件，选项会改变精神、牌组、遗物或绩效点。"
		"rest":
			return "茶水间休息，可以恢复精神或升级一张牌。"
		_:
			return "未知节点，进入前请确认当前路线。"


func _node_reward_hint(node_type: String) -> String:
	match node_type:
		"normal_battle":
			return "预期回报：卡牌候选、遗物候选、绩效点。"
		"elite_battle":
			return "预期回报：更高绩效点、精英奖励、职业解锁里程碑。"
		"boss":
			return "预期回报：章节推进或最终胜利结算。"
		"shop":
			return "可用操作：购买、删牌、刷新。"
		"event":
			return "可用操作：选择一个事件选项。"
		"rest":
			return "可用操作：恢复精神或复盘升级。"
		_:
			return "预期回报：未知。"


func _enter_node(node_id: String) -> void:
	var run := AppRoot.run_session.run_state
	var node: Dictionary = AppRoot.map_service.choose_node(run, node_id)
	if node.is_empty():
		return
	UiMotion.scan_line(self, UiMotion.SERVICE, 0.20)
	await get_tree().create_timer(0.14 if not UiMotion.reduce_motion() else 0.01).timeout
	match node.get("node_type", ""):
		"normal_battle", "elite_battle", "boss":
			AppRoot.battle_service.start_battle(run, node)
			AppRoot.flow_controller.show_scene("battle")
		"shop":
			AppRoot.flow_controller.show_scene("shop")
		"event":
			AppRoot.flow_controller.show_scene("event")
		"rest":
			AppRoot.flow_controller.show_scene("rest")
		_:
			AppRoot.flow_controller.show_scene("map")

func _animate_entry() -> void:
	var graph := find_child("MapGraphPanel", true, false)
	if graph != null:
		UiMotion.fade_in(graph, 0.22, Vector2(0, 18))
	var available: Array = AppRoot.run_session.run_state.get("map_state", {}).get("available_next_nodes", [])
	for button in _node_buttons.values():
		if button is Control and available.has(_node_id_from_button(button)):
			UiMotion.pulse(button, UiMotion.SERVICE, 0.22)
	var detail := find_child("NodeDetailPanel", true, false)
	if detail != null:
		UiMotion.fade_in(detail, 0.20, Vector2(18, 0))


func _node_id_from_button(button: Control) -> String:
	for node_id in _node_buttons.keys():
		if _node_buttons[node_id] == button:
			return String(node_id)
	return ""
