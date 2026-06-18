class_name ContentResolver
extends RefCounted

var config_service: ConfigService

func setup(p_config_service: ConfigService) -> void:
	config_service = p_config_service

func playable_classes(include_hr_placeholder := true) -> Array:
	return config_service.first_playable_classes(include_hr_placeholder)

func is_run_class_enabled(class_id: String) -> bool:
	var cls := class_def(class_id)
	return not cls.is_empty() and bool(cls.get("enabled_in_first_playable", false)) and class_id != "hr"

func class_def(class_id: String) -> Dictionary:
	return config_service.get_def("classes", class_id)

func card_def(card_id: String) -> Dictionary:
	return config_service.get_def("cards", card_id)

func relic_def(relic_id: String) -> Dictionary:
	return config_service.get_def("relics", relic_id)

func enemy_def(enemy_id: String) -> Dictionary:
	return config_service.get_def("enemies", enemy_id)

func event_def(event_id: String) -> Dictionary:
	return config_service.get_def("events", event_id)

func reward_profile(profile_id: String) -> Dictionary:
	return config_service.get_def("reward_profiles", profile_id)

func shop_pool(pool_id := "shop_default") -> Dictionary:
	return config_service.get_def("shop_pools", pool_id)

func initial_boost_def(boost_id: String) -> Dictionary:
	return config_service.get_def("initial_boosts", boost_id)

func initial_boosts_for_run_class(class_id: String, owned_relic_ids: Array = []) -> Array:
	if not is_run_class_enabled(class_id):
		return []
	var result: Array = []
	for boost in config_service.all_defs("initial_boosts"):
		if not bool(boost.get("enabled_in_first_playable", false)):
			continue
		var allowed: Array = boost.get("allowed_classes", [])
		if not allowed.has(class_id):
			continue
		var relic_id := String(boost.get("relic_id", ""))
		if not relic_id.is_empty() and owned_relic_ids.has(relic_id):
			continue
		if _boost_needs_random_relic(boost) and _available_relics_for_boost(class_id, owned_relic_ids).is_empty():
			continue
		result.append(boost)
	return result

func effect_entries(effect_group_id: String) -> Array:
	var group: Dictionary = config_service.get_def("effect_groups", effect_group_id)
	var entries: Array = group.get("entries", [])
	if not entries.is_empty():
		return entries
	var resolved: Array = []
	for entry_id in group.get("entry_ids", []):
		var entry: Dictionary = config_service.get_def("effect_entries", entry_id)
		if not entry.is_empty():
			resolved.append(entry)
	return resolved

func cards_for_run_class(class_id: String, include_shared := true) -> Array:
	if not is_run_class_enabled(class_id):
		return []
	return config_service.cards_for_class(class_id, include_shared, false)

func relics_for_run_class(class_id: String, include_starter := false) -> Array:
	if not is_run_class_enabled(class_id):
		return []
	return config_service.relics_for_class(class_id, include_starter)

func _boost_needs_random_relic(boost: Dictionary) -> bool:
	for effect in boost.get("effects", []):
		if String(effect.get("effect_type", "")) == "add_random_relic":
			return true
	return false

func _available_relics_for_boost(class_id: String, owned_relic_ids: Array) -> Array:
	var relics := relics_for_run_class(class_id)
	return relics.filter(func(relic): return not owned_relic_ids.has(String(relic.get("id", ""))))

func events_for_run_class(class_id: String, chapter: int) -> Array:
	if not is_run_class_enabled(class_id):
		return []
	var result: Array = []
	for event in config_service.all_defs("events"):
		var chapters: Array = event.get("chapter_tags", [])
		var classes: Array = event.get("allowed_classes", [])
		var chapter_matches := false
		for chapter_tag in chapters:
			if int(chapter_tag) == chapter:
				chapter_matches = true
				break
		var class_matches := false
		for allowed_class in classes:
			if String(allowed_class) == class_id:
				class_matches = true
				break
		if chapter_matches and class_matches:
			result.append(event)
	return result

func encounters_for_node(chapter: int, node_type: String, map_floor: int) -> Array:
	var result: Array = []
	for encounter in config_service.encounters_for(chapter, node_type):
		var min_floor := int(encounter.get("min_floor", 1))
		var max_floor := int(encounter.get("max_floor", 99))
		if map_floor >= min_floor and map_floor <= max_floor:
			result.append(encounter)
	return result

func intent_entries_for_enemy(enemy_id: String) -> Array:
	var enemy := enemy_def(enemy_id)
	var group: Dictionary = config_service.get_def("intent_groups", enemy.get("intent_group_id", ""))
	return group.get("intent_entries", [])

func phase_entries_for_enemy(enemy_id: String) -> Array:
	var enemy := enemy_def(enemy_id)
	var group: Dictionary = config_service.get_def("phase_groups", enemy.get("phase_group_id", ""))
	return group.get("phase_entries", [])

func weighted_pick(rows: Array, rng: RandomNumberGenerator) -> Dictionary:
	return config_service.random_weighted(rows, rng)
