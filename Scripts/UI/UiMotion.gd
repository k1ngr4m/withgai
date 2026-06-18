class_name UiMotion
extends RefCounted

const DAMAGE := Color(1.0, 0.35, 0.37)
const BLOCK := Color(0.45, 0.84, 0.91)
const CACHE := Color(0.40, 0.94, 0.64)
const SERVICE := Color(0.36, 0.84, 1.0)
const REQUEST := Color(1.0, 0.70, 0.33)
const REWARD := Color(1.0, 0.89, 0.43)
const WHITE_SCAN := Color(0.90, 0.98, 1.0)

static func reduce_motion() -> bool:
	var app = Engine.get_main_loop().root.get_node_or_null("/root/AppRoot")
	if app == null or app.meta_service == null:
		return false
	var settings: Dictionary = app.meta_service.meta_state.get("settings", {})
	return bool(settings.get("reduce_motion", false))


static func ambient_motion_enabled() -> bool:
	var app = Engine.get_main_loop().root.get_node_or_null("/root/AppRoot")
	if app == null or app.meta_service == null:
		return true
	var settings: Dictionary = app.meta_service.meta_state.get("settings", {})
	return bool(settings.get("ambient_motion", true))


static func screen_shake_enabled() -> bool:
	var app = Engine.get_main_loop().root.get_node_or_null("/root/AppRoot")
	if app == null or app.meta_service == null:
		return false
	var settings: Dictionary = app.meta_service.meta_state.get("settings", {})
	return bool(settings.get("screen_shake", false))


static func press(node: Control, duration := 0.10) -> void:
	if not is_instance_valid(node):
		return
	if reduce_motion():
		flash_modulate(node, WHITE_SCAN, 0.08)
		return
	var original := node.scale
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original * 0.96, duration * 0.45)
	tween.tween_property(node, "scale", original, duration * 0.55)


static func bind_button(button: Button, accent_color := SERVICE) -> void:
	if not is_instance_valid(button):
		return
	if button.has_meta("ui_motion_bound"):
		return
	button.set_meta("ui_motion_bound", true)
	button.pressed.connect(func():
		press(button)
		flash_modulate(button, accent_color, 0.12)
	)


static func bind_buttons(root: Node, accent_color := SERVICE) -> void:
	if not is_instance_valid(root):
		return
	for child in root.get_children():
		if child is Button:
			bind_button(child, accent_color)
		bind_buttons(child, accent_color)


static func shake(node: Control, amount := 8.0, duration := 0.14) -> void:
	if not is_instance_valid(node):
		return
	if reduce_motion():
		flash_modulate(node, DAMAGE, 0.12)
		return
	var original := node.position
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var steps := 4
	for i in range(steps):
		var dir := -1.0 if i % 2 == 0 else 1.0
		tween.tween_property(node, "position", original + Vector2(amount * dir, 0), duration / float(steps + 1))
	tween.tween_property(node, "position", original, duration / float(steps + 1))


static func pulse(node: CanvasItem, color: Color, duration := 0.18) -> void:
	if not is_instance_valid(node):
		return
	var original := node.modulate
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate", color, duration * 0.45)
	tween.tween_property(node, "modulate", original, duration * 0.55)


static func flash_modulate(node: CanvasItem, color: Color, duration := 0.16) -> void:
	pulse(node, color, duration)


static func fade_in(node: CanvasItem, duration := 0.20, offset := Vector2.ZERO) -> void:
	if not is_instance_valid(node):
		return
	var original_modulate := node.modulate
	var original_position := Vector2.ZERO
	var is_control := node is Control
	if is_control:
		original_position = (node as Control).position
	node.modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, 0.0)
	if is_control and not reduce_motion():
		(node as Control).position = original_position + offset
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate", original_modulate, 0.05 if reduce_motion() else duration)
	if is_control and not reduce_motion():
		tween.parallel().tween_property(node, "position", original_position, duration)


static func fade_in_children(parent: Node, duration := 0.18, offset := Vector2(0, 16), stagger := 0.04) -> void:
	if not is_instance_valid(parent):
		return
	var index := 0
	for child in parent.get_children():
		if child is CanvasItem:
			var delay := 0.0 if reduce_motion() else float(index) * stagger
			var child_item := child as CanvasItem
			var original_modulate := child_item.modulate
			var original_position := Vector2.ZERO
			var is_control := child_item is Control
			if is_control:
				original_position = (child_item as Control).position
			child_item.modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, 0.0)
			if is_control and not reduce_motion():
				(child_item as Control).position = original_position + offset
			var tween := child_item.create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_interval(delay)
			tween.tween_property(child_item, "modulate", original_modulate, 0.05 if reduce_motion() else duration)
			if is_control and not reduce_motion():
				tween.parallel().tween_property(child_item, "position", original_position, duration)
			index += 1


static func pop_in(node: Control, duration := 0.22) -> void:
	if not is_instance_valid(node):
		return
	if reduce_motion():
		fade_in(node, 0.05)
		return
	var original := node.scale
	node.pivot_offset = node.size * 0.5
	node.scale = original * 0.94
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original, duration)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.75)


static func float_text(parent: Control, text: String, color: Color, from: Vector2) -> void:
	if not is_instance_valid(parent) or text.is_empty():
		return
	var label := Label.new()
	label.text = text
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.92))
	label.position = from
	parent.add_child(label)
	if reduce_motion():
		var t0 := label.create_tween()
		t0.tween_interval(0.20)
		t0.tween_callback(label.queue_free)
		return
	var tween := label.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position", from + Vector2(0, -48), 0.48)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.48)
	tween.tween_callback(label.queue_free)


static func scan_line(parent: Control, color := SERVICE, duration := 0.26) -> void:
	if not is_instance_valid(parent):
		return
	var line := ColorRect.new()
	line.color = Color(color.r, color.g, color.b, 0.72)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 90
	line.custom_minimum_size = Vector2(maxf(parent.size.x, 120.0), 3)
	line.size = Vector2(maxf(parent.size.x, 120.0), 3)
	line.position = Vector2(-line.size.x, maxf(8.0, parent.size.y * 0.45))
	parent.add_child(line)
	if reduce_motion():
		line.queue_free()
		return
	var tween := line.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "position:x", parent.size.x, duration)
	tween.parallel().tween_property(line, "modulate:a", 0.0, duration)
	tween.tween_callback(line.queue_free)


static func short_trail(parent: Control, from: Vector2, to: Vector2, color := SERVICE, duration := 0.20) -> void:
	if not is_instance_valid(parent):
		return
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 90
	line.color = Color(color.r, color.g, color.b, 0.78)
	var delta := to - from
	line.position = from
	line.size = Vector2(maxf(2.0, absf(delta.x)), 3)
	if absf(delta.x) < 2.0:
		line.size = Vector2(3, maxf(2.0, absf(delta.y)))
	parent.add_child(line)
	var tween := line.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, 0.05 if reduce_motion() else duration)
	tween.tween_callback(line.queue_free)


static func apply_panel_style(panel: PanelContainer, border_color: Color, bg_alpha := 0.82) -> void:
	if not is_instance_valid(panel):
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.09, bg_alpha)
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
