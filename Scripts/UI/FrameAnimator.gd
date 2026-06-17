class_name FrameAnimator
extends TextureRect

var _timer: Timer
var _idle_textures: Array = []
var _active_textures: Array = []
var _action_paths: Dictionary = {}
var _frame_index := 0
var _fps := 6
var _loop := true

func setup(idle_paths: Array, fallback_path: String, fps: int, min_size := Vector2(320, 210)) -> void:
	custom_minimum_size = min_size
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fps = max(1, fps)
	_idle_textures = _load_textures(idle_paths)
	if _idle_textures.is_empty() and not fallback_path.is_empty():
		var fallback = load(fallback_path)
		if fallback != null:
			_idle_textures = [fallback]
	_play_idle()

func setup_actions(action_paths: Dictionary, fallback_path: String, fps: int, min_size := Vector2(320, 210)) -> void:
	_action_paths = action_paths.duplicate(true)
	setup(action_paths.get("idle", []), fallback_path, fps, min_size)

func play_once(frame_paths: Array) -> void:
	var textures := _load_textures(frame_paths)
	if textures.is_empty():
		_play_idle()
		return
	_play(textures, false)

func play_action(action: String) -> void:
	if action.is_empty() or not _action_paths.has(action):
		_play_idle()
		return
	play_once(_action_paths.get(action, []))

func _play_idle() -> void:
	_play(_idle_textures, true)

func _play(textures: Array, should_loop: bool) -> void:
	_ensure_timer()
	_active_textures = textures
	_loop = should_loop
	_frame_index = 0
	if _active_textures.is_empty():
		texture = null
		_timer.stop()
		return
	texture = _active_textures[0]
	if _active_textures.size() == 1:
		_timer.stop()
		return
	_timer.wait_time = 1.0 / float(_fps)
	_timer.start()

func _ensure_timer() -> void:
	if _timer != null:
		return
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_advance_frame)
	add_child(_timer)

func _advance_frame() -> void:
	if _active_textures.is_empty():
		_timer.stop()
		return
	_frame_index += 1
	if _frame_index >= _active_textures.size():
		if _loop:
			_frame_index = 0
		else:
			_play_idle()
			return
	texture = _active_textures[_frame_index]

func _load_textures(paths: Array) -> Array:
	var textures: Array = []
	for path_value in paths:
		var path := String(path_value)
		if path.is_empty():
			continue
		var loaded = load(path)
		if loaded != null:
			textures.append(loaded)
	return textures
