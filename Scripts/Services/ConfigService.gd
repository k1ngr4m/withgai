class_name ConfigService
extends RefCounted

const CONFIG_PATH := "res://Data/Generated/Config/game_config.json"

var data: Dictionary = {}

func load_config() -> void:
	var text := FileAccess.get_file_as_string(CONFIG_PATH)
	if text.is_empty():
		push_error("ConfigService: missing config at %s" % CONFIG_PATH)
		data = {}
		return
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ConfigService: invalid JSON config")
		data = {}
		return
	data = parsed

func get_table(table_name: String) -> Dictionary:
	return data.get(table_name, {})

func get_def(table_name: String, id: String) -> Dictionary:
	return get_table(table_name).get(id, {})

func all_defs(table_name: String) -> Array:
	return get_table(table_name).values()

func first_playable_classes(include_hr := true) -> Array:
	var result: Array = []
	for cls in all_defs("classes"):
		if cls.get("enabled_in_first_playable", false) or (include_hr and cls.get("id", "") == "hr"):
			result.append(cls)
	result.sort_custom(func(a, b): return int(a.get("unlock_order", 0)) < int(b.get("unlock_order", 0)))
	return result

func cards_for_class(class_id: String, include_shared := true, include_disabled := false) -> Array:
	var cls: Dictionary = get_def("classes", class_id)
	var shared_refs: Array = cls.get("shared_pool_refs", [])
	var result: Array = []
	for card in all_defs("cards"):
		if not include_disabled and not card.get("enabled_in_first_playable", false):
			continue
		var tags: Array = card.get("class_tags", [])
		if tags.has(class_id):
			result.append(card)
		elif include_shared:
			for tag in tags:
				if shared_refs.has(tag):
					result.append(card)
					break
	return result

func relics_for_class(class_id: String, include_starter := false) -> Array:
	var result: Array = []
	for relic in all_defs("relics"):
		if not include_starter and relic.get("rarity", "") == "starter":
			continue
		var allowed: Array = relic.get("allowed_classes", [])
		if allowed.has(class_id):
			result.append(relic)
	return result

func encounters_for(chapter: int, node_type: String) -> Array:
	var result: Array = []
	for encounter in all_defs("encounters"):
		if int(encounter.get("chapter", 0)) == chapter and encounter.get("node_type", "") == node_type:
			result.append(encounter)
	return result

func random_weighted(rows: Array, rng: RandomNumberGenerator) -> Dictionary:
	if rows.is_empty():
		return {}
	var total := 0
	for row in rows:
		total += int(row.get("weight", 1))
	var roll := rng.randi_range(1, max(total, 1))
	var cursor := 0
	for row in rows:
		cursor += int(row.get("weight", 1))
		if roll <= cursor:
			return row
	return rows[0]

func effect_entries(effect_group_id: String) -> Array:
	return get_def("effect_groups", effect_group_id).get("entries", [])
