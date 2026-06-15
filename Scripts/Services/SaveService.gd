class_name SaveService
extends RefCounted

const META_PATH := "user://withgai_meta.json"
const SUSPEND_PATH := "user://withgai_suspend.json"

func load_json(path: String, fallback) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	return parsed if parsed != null else fallback

func save_json(path: String, value) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: cannot open %s" % path)
		return
	file.store_string(JSON.stringify(value, "\t"))

func load_meta(fallback: Dictionary) -> Dictionary:
	var loaded = load_json(META_PATH, fallback)
	return loaded if typeof(loaded) == TYPE_DICTIONARY else fallback

func save_meta(meta_state: Dictionary) -> void:
	save_json(META_PATH, meta_state)

func has_suspend() -> bool:
	return FileAccess.file_exists(SUSPEND_PATH)

func load_suspend() -> Dictionary:
	var loaded = load_json(SUSPEND_PATH, {})
	return loaded if typeof(loaded) == TYPE_DICTIONARY else {}

func save_suspend(run_state: Dictionary, meta_state: Dictionary = {}) -> void:
	save_json(SUSPEND_PATH, {
		"save_version": 1,
		"scene_tag": run_state.get("current_scene_tag", "map"),
		"serialized_run_state": run_state,
		"serialized_meta_state_snapshot": meta_state,
		"timestamp": Time.get_unix_time_from_system(),
	})

func clear_suspend() -> void:
	if FileAccess.file_exists(SUSPEND_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SUSPEND_PATH))
