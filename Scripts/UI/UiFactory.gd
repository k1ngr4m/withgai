class_name UiFactory
extends RefCounted

const CardFaceButtonScript := preload("res://Scripts/UI/CardFaceButton.gd")

static func fill(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

static func add_background(parent: Control, path: String) -> void:
	if path.is_empty():
		return
	var loaded_texture = load(path)
	if loaded_texture == null:
		return
	var bg := TextureRect.new()
	fill(bg)
	bg.texture = loaded_texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.72, 0.72, 0.72, 1.0)
	parent.add_child(bg)

static func margin(parent: Control, size := 24) -> MarginContainer:
	var box := MarginContainer.new()
	fill(box)
	box.add_theme_constant_override("margin_left", size)
	box.add_theme_constant_override("margin_right", size)
	box.add_theme_constant_override("margin_top", size)
	box.add_theme_constant_override("margin_bottom", size)
	parent.add_child(box)
	return box

static func panel() -> PanelContainer:
	var panel_container := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.09, 0.82)
	style.border_color = Color(0.58, 0.72, 0.82, 0.6)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel_container.add_theme_stylebox_override("panel", style)
	return panel_container

static func label(text: String, size := 18, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 42)
	UiMotion.bind_button(b)
	return b

static func card_button(card: Dictionary, _text := "", min_size := Vector2(190, 260), options := {}) -> Button:
	var b: Button = CardFaceButtonScript.new()
	b.custom_minimum_size = min_size
	if b.has_method("setup_card"):
		b.call("setup_card", card, options)
	UiMotion.bind_button(b)
	return b

static func vbox(separation := 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

static func hbox(separation := 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s

static func texture(path: String, min_size := Vector2(160, 120)) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = min_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not path.is_empty():
		var tex = load(path)
		if tex != null:
			rect.texture = tex
	return rect

static func type_name(node_type: String) -> String:
	match node_type:
		"normal_battle":
			return "普通战斗"
		"elite_battle":
			return "精英战斗"
		"rest":
			return "休息处"
		"shop":
			return "商店"
		"event":
			return "随机事件"
		"boss":
			return "Boss"
		_:
			return node_type
