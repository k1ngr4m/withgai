extends Control

var _selected_node_id := ""
var _node_buttons := {}
var _node_detail_box: VBoxContainer
var _enter_button: Button


func _ready() -> void:
	_build()


func _build() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_map_floor_navigation_v1.png")
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

	var graph := UiFactory.hbox(14)
	graph.name = "MapGraphPanel"
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(UiFactory.scroll(graph))

	var side := UiFactory.vbox(10)
	side.custom_minimum_size = Vector2(300, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	side.add_child(_floor_info_panel(run, cls))
	side.add_child(_node_detail_panel())

	var available: Array = run.get("map_state", {}).get("available_next_nodes", [])
	var visited: Array = run.get("visited_node_ids", [])
	_selected_node_id = _default_selected_node(available, visited)
	_node_buttons.clear()
	for layer in run.get("map_state", {}).get("floors", []):
		var column := UiFactory.vbox(10)
		graph.add_child(column)
		for node in layer:
			var node_id := String(node.get("id", ""))
			var b: Button = UiFactory.button(_node_button_text(node, node_id == _selected_node_id, visited.has(node_id)))
			b.name = "MapNodeButton%s" % node_id.capitalize()
			b.disabled = not available.has(node.get("id", "")) or visited.has(node.get("id", ""))
			b.tooltip_text = "查看节点详情" if not b.disabled else "当前路线不可进入"
			b.pressed.connect(func(): _select_node(node_id))
			_node_buttons[node_id] = b
			column.add_child(b)
	_refresh_node_details()

	var bottom := UiFactory.hbox(8)
	main.add_child(bottom)
	var save := UiFactory.button("保存")
	save.name = "SaveButton"
	save.pressed.connect(func(): AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state))
	bottom.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "MainMenuButton"
	menu.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	bottom.add_child(menu)


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
	_refresh_node_buttons()
	_refresh_node_details()


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
	if node.is_empty() or not available.has(_selected_node_id) or visited.has(_selected_node_id):
		_node_detail_box.add_child(UiFactory.label("选择一个可前进节点", 20))
		_node_detail_box.add_child(UiFactory.label("左侧亮起的楼层节点可以进入。", 14, Color(0.74, 0.86, 0.88)))
		_set_enter_button_state(false, "进入选中节点")
		return

	var node_type := String(node.get("node_type", ""))
	_node_detail_box.add_child(UiFactory.label("%dF  %s" % [int(node.get("floor", 0)), UiFactory.type_name(node_type)], 22))
	_node_detail_box.add_child(UiFactory.label(_node_flavor(node_type), 14, Color(0.78, 0.90, 0.92)))
	_node_detail_box.add_child(UiFactory.label(_node_reward_hint(node_type), 14, Color(0.92, 0.84, 0.58)))
	_node_detail_box.add_child(UiFactory.label("后续路线：%d 条" % int(node.get("next_ids", []).size()), 13, Color(0.65, 0.78, 0.80)))
	_set_enter_button_state(true, "进入 %dF %s" % [int(node.get("floor", 0)), UiFactory.type_name(node_type)])


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
