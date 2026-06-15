class_name MapService
extends RefCounted

var config_service: ConfigService

func setup(p_config_service: ConfigService) -> void:
	config_service = p_config_service

func generate_chapter(run_state: Dictionary, chapter: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run_state.get("rng_seed", 1)) + chapter * 1009
	var floors: Array = []
	for local_floor in range(6):
		var node_count := 1 if local_floor == 5 else 3
		var layer: Array = []
		for index in range(node_count):
			var node_type := _node_type_for(chapter, local_floor, index, rng)
			var global_floor := (chapter - 1) * 6 + local_floor + 1
			layer.append({
				"id": "ch%d_f%d_n%d" % [chapter, global_floor, index],
				"chapter": chapter,
				"floor": global_floor,
				"local_floor": local_floor,
				"index": index,
				"node_type": node_type,
				"next_ids": [],
				"visited": false,
			})
		floors.append(layer)
	for i in range(floors.size() - 1):
		for node in floors[i]:
			for next_node in floors[i + 1]:
				if abs(int(node["index"]) - int(next_node["index"])) <= 1 or floors[i + 1].size() == 1:
					node["next_ids"].append(next_node["id"])
	run_state["current_chapter"] = chapter
	run_state["map_state"] = {
		"chapter_index": chapter,
		"floors": floors,
		"node_graph": {},
		"visited_nodes": [],
		"available_next_nodes": floors[0].map(func(node): return node["id"]),
		"boss_node_id": floors[5][0]["id"],
	}

func _node_type_for(chapter: int, local_floor: int, index: int, rng: RandomNumberGenerator) -> String:
	if local_floor == 0:
		return "normal_battle"
	if local_floor == 5:
		return "boss"
	if local_floor == 3 and index == 1:
		return "rest"
	if local_floor == 2 and index == 2:
		return "shop"
	var pool := ["normal_battle", "normal_battle", "event", "elite_battle", "rest", "shop"]
	return pool[rng.randi_range(0, pool.size() - 1)]

func find_node(run_state: Dictionary, node_id: String) -> Dictionary:
	for layer in run_state.get("map_state", {}).get("floors", []):
		for node in layer:
			if node.get("id", "") == node_id:
				return node
	return {}

func choose_node(run_state: Dictionary, node_id: String) -> Dictionary:
	var available: Array = run_state.get("map_state", {}).get("available_next_nodes", [])
	if not available.has(node_id):
		return {}
	var node := find_node(run_state, node_id)
	if node.is_empty():
		return {}
	run_state["current_node_id"] = node_id
	run_state["current_floor"] = int(node.get("floor", run_state.get("current_floor", 1)))
	return node

func complete_current_node(run_state: Dictionary) -> String:
	var node: Dictionary = find_node(run_state, run_state.get("current_node_id", ""))
	if node.is_empty():
		return "map"
	node["visited"] = true
	var visited: Array = run_state.get("visited_node_ids", [])
	if not visited.has(node["id"]):
		visited.append(node["id"])
	run_state["visited_node_ids"] = visited
	var map_state: Dictionary = run_state.get("map_state", {})
	map_state["visited_nodes"] = visited
	if node.get("node_type", "") == "boss":
		var boss_id: String = _boss_for_chapter(int(run_state.get("current_chapter", 1)))
		var defeated: Array = run_state.get("defeated_boss_ids", [])
		if not defeated.has(boss_id):
			defeated.append(boss_id)
		run_state["defeated_boss_ids"] = defeated
		if int(run_state.get("current_chapter", 1)) >= 3:
			return "run_victory"
		generate_chapter(run_state, int(run_state.get("current_chapter", 1)) + 1)
		return "next_chapter"
	map_state["available_next_nodes"] = node.get("next_ids", []).duplicate(true)
	run_state["map_state"] = map_state
	return "map"

func _boss_for_chapter(chapter: int) -> String:
	if chapter == 1:
		return "boss_pitch_supervisor"
	if chapter == 2:
		return "boss_mutant_hr"
	return "boss_mutant_ceo"
