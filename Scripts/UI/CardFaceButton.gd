class_name CardFaceButton
extends Button

const TYPE_NAMES := {
	"attack": "攻击",
	"skill": "技能",
	"power": "能力",
	"status": "状态",
	"curse": "诅咒",
}

var _frame: PanelContainer
var _title_label: Label
var _art_rect: TextureRect
var _type_label: Label
var _desc_label: Label
var _cost_badge: PanelContainer
var _cost_label: Label
var _badge_label: Label
var _placeholder_label: Label

func _init() -> void:
	text = ""
	clip_text = true
	custom_minimum_size = Vector2(190, 260)
	focus_mode = Control.FOCUS_NONE
	_setup_button_style()
	_build()


func setup_card(card: Dictionary, options: Dictionary = {}) -> void:
	var name_text := String(card.get("name", card.get("id", "")))
	var type_id := String(card.get("type", ""))
	var cost_text := String(options.get("cost_text", _default_cost_text(card)))
	var badge_text := String(options.get("badge_text", ""))
	var desc_text := _trim_description(String(card.get("description", "")), name_text)
	var art_path := String(card.get("art_path", ""))

	_title_label.text = name_text
	_cost_label.text = cost_text
	_type_label.text = String(TYPE_NAMES.get(type_id, type_id))
	_desc_label.text = desc_text
	_badge_label.text = badge_text
	_badge_label.visible = not badge_text.is_empty()

	_art_rect.texture = null
	_placeholder_label.visible = true
	if not art_path.is_empty():
		var tex = load(art_path)
		if tex != null:
			_art_rect.texture = tex
			_placeholder_label.visible = false

	set_selected(bool(options.get("selected", false)))
	_position_overlays()


func set_selected(selected: bool) -> void:
	var style := _frame.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.border_color = Color(1.0, 0.88, 0.34, 1.0) if selected else Color(0.72, 0.19, 0.22, 1.0)
	style.shadow_color = Color(1.0, 0.82, 0.22, 0.42) if selected else Color(0, 0, 0, 0.45)
	_frame.add_theme_stylebox_override("panel", style)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _cost_badge != null:
		_position_overlays()


func _build() -> void:
	_frame = PanelContainer.new()
	_frame.name = "CardFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.add_theme_stylebox_override("panel", _frame_style())
	add_child(_frame)

	var margin := MarginContainer.new()
	margin.name = "CardInnerMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_frame.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "CardLayout"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title_panel := PanelContainer.new()
	title_panel.name = "CardTitleRibbon"
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.custom_minimum_size = Vector2(0, 30)
	title_panel.add_theme_stylebox_override("panel", _title_style())
	box.add_child(title_panel)

	_title_label = Label.new()
	_title_label.name = "CardTitle"
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.clip_text = true
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.94, 1.0, 0.96, 1.0))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.03, 0.09, 0.10, 0.9))
	_title_label.add_theme_constant_override("shadow_offset_x", 1)
	_title_label.add_theme_constant_override("shadow_offset_y", 1)
	title_panel.add_child(_title_label)

	var art_panel := PanelContainer.new()
	art_panel.name = "CardArtWindow"
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.custom_minimum_size = Vector2(0, 84)
	art_panel.add_theme_stylebox_override("panel", _art_style())
	box.add_child(art_panel)

	var art_stack := Control.new()
	art_stack.name = "CardArtStack"
	art_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.add_child(art_stack)

	_art_rect = TextureRect.new()
	_art_rect.name = "CardArt"
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_stack.add_child(_art_rect)

	_placeholder_label = Label.new()
	_placeholder_label.name = "CardArtPlaceholder"
	_placeholder_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placeholder_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placeholder_label.text = "◇"
	_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder_label.add_theme_font_size_override("font_size", 42)
	_placeholder_label.add_theme_color_override("font_color", Color(0.42, 0.86, 0.88, 0.62))
	art_stack.add_child(_placeholder_label)

	var type_panel := PanelContainer.new()
	type_panel.name = "CardTypePlate"
	type_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_panel.custom_minimum_size = Vector2(0, 23)
	type_panel.add_theme_stylebox_override("panel", _type_style())
	box.add_child(type_panel)

	_type_label = Label.new()
	_type_label.name = "CardType"
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_label.add_theme_font_size_override("font_size", 14)
	_type_label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.98, 1.0))
	type_panel.add_child(_type_label)

	var desc_panel := PanelContainer.new()
	desc_panel.name = "CardDescriptionBox"
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.custom_minimum_size = Vector2(0, 68)
	desc_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_panel.add_theme_stylebox_override("panel", _desc_style())
	box.add_child(desc_panel)

	var desc_margin := MarginContainer.new()
	desc_margin.name = "CardDescriptionMargin"
	desc_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_margin.add_theme_constant_override("margin_left", 7)
	desc_margin.add_theme_constant_override("margin_right", 7)
	desc_margin.add_theme_constant_override("margin_top", 6)
	desc_margin.add_theme_constant_override("margin_bottom", 6)
	desc_panel.add_child(desc_margin)

	_desc_label = Label.new()
	_desc_label.name = "CardDescription"
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_label.custom_minimum_size = Vector2(0, 42)
	_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_desc_label.clip_text = true
	_desc_label.add_theme_font_size_override("font_size", 13)
	_desc_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.94, 1.0))
	_desc_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	_desc_label.add_theme_constant_override("shadow_offset_x", 1)
	_desc_label.add_theme_constant_override("shadow_offset_y", 1)
	desc_margin.add_child(_desc_label)

	_cost_badge = PanelContainer.new()
	_cost_badge.name = "CardCostBadge"
	_cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_badge.add_theme_stylebox_override("panel", _cost_style())
	add_child(_cost_badge)

	_cost_label = Label.new()
	_cost_label.name = "CardCost"
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_size_override("font_size", 23)
	_cost_label.add_theme_color_override("font_color", Color.WHITE)
	_cost_label.add_theme_color_override("font_shadow_color", Color(0.38, 0.12, 0.02, 0.9))
	_cost_label.add_theme_constant_override("shadow_offset_x", 1)
	_cost_label.add_theme_constant_override("shadow_offset_y", 1)
	_cost_badge.add_child(_cost_label)

	_badge_label = Label.new()
	_badge_label.name = "CardBadge"
	_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label.add_theme_font_size_override("font_size", 13)
	_badge_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55, 1.0))
	_badge_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_badge_label.add_theme_constant_override("shadow_offset_x", 1)
	_badge_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_badge_label)


func _setup_button_style() -> void:
	var empty := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style_name, empty)


func _position_overlays() -> void:
	var cost_badge_size := Vector2(46, 46)
	_cost_badge.size = cost_badge_size
	_cost_badge.position = Vector2(-4, -5)
	if _badge_label == null:
		return
	var badge_size := _badge_label.get_combined_minimum_size()
	_badge_label.size = badge_size
	_badge_label.position = Vector2(max(6.0, size.x - badge_size.x - 7.0), 8.0)


func _default_cost_text(card: Dictionary) -> String:
	var cost := int(card.get("cost", 0))
	return "X" if cost < 0 else str(cost)


func _trim_description(description: String, card_name: String) -> String:
	var prefix := "%s：" % card_name
	if description.begins_with(prefix):
		return description.substr(prefix.length()).strip_edges()
	return description.strip_edges()


func _frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.30, 0.07, 0.08, 0.96)
	style.border_color = Color(0.72, 0.19, 0.22, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	return style


func _title_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.82, 0.85, 0.94)
	style.border_color = Color(0.61, 1.0, 0.96, 0.92)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _art_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.035, 1.0)
	style.border_color = Color(0.52, 0.96, 0.96, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	return style


func _type_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.30, 0.28, 0.94)
	style.border_color = Color(0.57, 0.96, 0.90, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _desc_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.16, 0.15, 0.92)
	style.border_color = Color(0.50, 0.28, 0.28, 0.75)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _cost_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.47, 0.08, 1.0)
	style.border_color = Color(1.0, 0.87, 0.25, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.shadow_color = Color(0.45, 0.06, 0.02, 0.7)
	style.shadow_size = 4
	return style
