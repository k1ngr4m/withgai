extends Control

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
	main.add_child(UiFactory.label("第 %d 章 | 当前楼层 %d | %s | 精神 %d/%d | 绩效点 %d" % [
		int(run.get("current_chapter", 1)),
		int(run.get("current_floor", 1)),
		cls.get("name", ""),
		int(run.get("player_state", {}).get("current_spirit", 0)),
		int(run.get("player_state", {}).get("max_spirit", 0)),
		int(run.get("currency_perf_points", 0)),
	], 24))
	var graph := UiFactory.hbox(14)
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(UiFactory.scroll(graph))
	var available: Array = run.get("map_state", {}).get("available_next_nodes", [])
	var visited: Array = run.get("visited_node_ids", [])
	for layer in run.get("map_state", {}).get("floors", []):
		var column := UiFactory.vbox(10)
		graph.add_child(column)
		for node in layer:
			var b: Button = UiFactory.button("%dF\n%s" % [int(node.get("floor", 0)), UiFactory.type_name(node.get("node_type", ""))])
			b.disabled = not available.has(node.get("id", "")) or visited.has(node.get("id", ""))
			if visited.has(node.get("id", "")):
				b.text += "\n已完成"
			var node_id := String(node.get("id", ""))
			b.pressed.connect(func(): _enter_node(node_id))
			column.add_child(b)
	var bottom := UiFactory.hbox(8)
	main.add_child(bottom)
	var save := UiFactory.button("保存")
	save.pressed.connect(func(): AppRoot.save_service.save_suspend(AppRoot.run_session.run_state))
	bottom.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	bottom.add_child(menu)

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
