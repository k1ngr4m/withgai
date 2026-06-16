extends Control

const MAIN_BG := "res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png"
const CLASS_PREVIEWS := [
	{
		"name": "后端",
		"summary": "稳健、防守、服务引擎",
		"color": Color("#3AA7A3"),
		"art": "res://Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/final.png",
	},
	{
		"name": "前端",
		"summary": "连击、组件、样式层",
		"color": Color("#E676AF"),
		"art": "res://Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/final.png",
	},
	{
		"name": "测试",
		"summary": "Bug、用例、Diff 锁场",
		"color": Color("#F0B64D"),
		"art": "res://Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/final.png",
	},
	{
		"name": "算法",
		"summary": "算力、复杂度、高爆发",
		"color": Color("#8B7FF5"),
		"art": "res://Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/final.png",
	},
	{
		"name": "产品经理",
		"summary": "需求变更、意图操控",
		"color": Color("#6BB7F0"),
		"art": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
	},
]

func _ready() -> void:
	UiFactory.fill(self)
	UiFactory.add_background(self, MAIN_BG)
	_add_scrim(Color(0.02, 0.03, 0.04, 0.42))
	_build_menu()

func _build_menu() -> void:
	var margin := UiFactory.margin(self, 44)
	var root := UiFactory.vbox(24)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	root.add_child(_top_bar())

	var main := UiFactory.hbox(30)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)

	var hero := _hero_section()
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(hero)

	var menu := _menu_panel()
	menu.custom_minimum_size = Vector2(380, 0)
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(menu)

	root.add_child(_class_strip())

func _top_bar() -> Control:
	var top := UiFactory.hbox(12)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var brand := UiFactory.label("WITHGAI", 18, Color(0.90, 0.97, 1.0))
	brand.add_theme_constant_override("outline_size", 2)
	brand.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	top.add_child(brand)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	top.add_child(_status_chip("夜班版本"))
	top.add_child(_status_chip("五组值班"))
	top.add_child(_status_chip("HR 档案封存"))
	return top

func _hero_section() -> Control:
	var hero := VBoxContainer.new()
	hero.add_theme_constant_override("separation", 18)
	hero.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := UiFactory.label("withgai", 78, Color(0.95, 0.99, 1.0))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.05, 0.92))
	hero.add_child(title)

	var subtitle := UiFactory.label("写字楼爬楼卡牌肉鸽", 30, Color(0.90, 0.95, 0.96))
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.05, 0.92))
	hero.add_child(subtitle)

	var copy := UiFactory.label("从开放工位一路打到 CEO 楼层。抽牌、加班、甩锅，然后活着下班。", 20, Color(0.78, 0.86, 0.88))
	copy.custom_minimum_size = Vector2(560, 0)
	hero.add_child(copy)

	var stats := UiFactory.hbox(10)
	stats.add_child(_metric_chip("195", "张卡牌"))
	stats.add_child(_metric_chip("16", "名敌人"))
	stats.add_child(_metric_chip("3", "章流程"))
	hero.add_child(stats)

	var save_info := _save_info_panel()
	save_info.custom_minimum_size = Vector2(560, 104)
	hero.add_child(save_info)
	return hero

func _menu_panel() -> PanelContainer:
	var panel := _panel(Color(0.04, 0.06, 0.08, 0.86), Color(0.61, 0.79, 0.88, 0.62), 8)
	var pad := _pad(24)
	panel.add_child(pad)

	var box := UiFactory.vbox(14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	box.add_child(UiFactory.label("开始值班", 30, Color(0.95, 0.98, 1.0)))
	box.add_child(UiFactory.label("选择一条职业路线，进入今天的办公楼异常处理。", 16, Color(0.72, 0.80, 0.82)))

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(1, 10)
	box.add_child(spacer_top)

	var new_button := _menu_button("新开一局", true)
	new_button.pressed.connect(func(): AppRoot.flow_controller.show_scene("class_select"))
	box.add_child(new_button)

	var continue_button := _menu_button("继续中断档", false)
	continue_button.disabled = not AppRoot.save_service.has_suspend()
	continue_button.pressed.connect(_continue_run)
	box.add_child(continue_button)

	var meta_button := _menu_button("工位成长", false)
	meta_button.pressed.connect(func(): AppRoot.flow_controller.show_scene("meta"))
	box.add_child(meta_button)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)

	var meta := AppRoot.meta_service.meta_state
	var currency := int(meta.get("owned_discomfort_currency", 0))
	var floor_record := int(meta.get("highest_floor_reached", 1))
	box.add_child(_record_row("不适点", str(currency)))
	box.add_child(_record_row("最高楼层", str(floor_record)))

	var quit_button := _menu_button("退出", false)
	quit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(quit_button)
	return panel

func _class_strip() -> PanelContainer:
	var panel := _panel(Color(0.03, 0.045, 0.06, 0.78), Color(0.45, 0.63, 0.72, 0.50), 8)
	var pad := _pad(14)
	panel.add_child(pad)

	var row := UiFactory.hbox(12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(row)
	for item in CLASS_PREVIEWS:
		row.add_child(_class_preview(item))
	return panel

func _class_preview(item: Dictionary) -> PanelContainer:
	var accent: Color = item.get("color", Color.WHITE)
	var panel := _panel(Color(0.07, 0.09, 0.11, 0.84), accent.darkened(0.18), 7)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(150, 96)

	var pad := _pad(10)
	panel.add_child(pad)
	var row := UiFactory.hbox(10)
	pad.add_child(row)

	var portrait := UiFactory.texture(String(item.get("art", "")), Vector2(62, 62))
	portrait.modulate = Color(1, 1, 1, 0.94)
	row.add_child(portrait)

	var text := UiFactory.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)

	text.add_child(UiFactory.label(String(item.get("name", "")), 18, accent.lightened(0.18)))
	text.add_child(UiFactory.label(String(item.get("summary", "")), 13, Color(0.76, 0.84, 0.86)))
	return panel

func _save_info_panel() -> PanelContainer:
	var panel := _panel(Color(0.02, 0.04, 0.05, 0.72), Color(0.55, 0.72, 0.80, 0.48), 8)
	var pad := _pad(18)
	panel.add_child(pad)

	var box := UiFactory.vbox(6)
	pad.add_child(box)
	box.add_child(UiFactory.label("当前存档", 18, Color(0.86, 0.95, 0.98)))
	var line := "没有中断档"
	if AppRoot.save_service.has_suspend():
		var suspend := AppRoot.save_service.load_suspend()
		line = "%s / 第 %d 层" % [String(suspend.get("selected_class_id", "未知职业")), int(suspend.get("current_floor", 1))]
	box.add_child(UiFactory.label(line, 16, Color(0.70, 0.80, 0.83)))
	box.add_child(UiFactory.label("今天的楼层记录、工位状态和未处理事项都在这里汇总。", 14, Color(0.55, 0.65, 0.68)))
	return panel

func _menu_button(text: String, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	var normal := _button_style(primary, false)
	var hover := _button_style(primary, true)
	var disabled := _button_style(false, false)
	disabled.bg_color = Color(0.12, 0.13, 0.14, 0.68)
	disabled.border_color = Color(0.32, 0.36, 0.38, 0.38)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.50, 0.56, 0.58))
	return button

func _button_style(primary: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.14, 0.92)
	style.border_color = Color(0.50, 0.67, 0.75, 0.55)
	if primary:
		style.bg_color = Color(0.12, 0.46, 0.48, 0.94)
		style.border_color = Color(0.58, 0.95, 0.92, 0.85)
	if hover:
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = style.border_color.lightened(0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style

func _record_row(label_text: String, value_text: String) -> Control:
	var row := UiFactory.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := UiFactory.label(label_text, 15, Color(0.64, 0.74, 0.77))
	row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(UiFactory.label(value_text, 17, Color(0.93, 0.98, 1.0)))
	return row

func _metric_chip(value: String, label_text: String) -> PanelContainer:
	var panel := _panel(Color(0.05, 0.075, 0.09, 0.76), Color(0.46, 0.62, 0.70, 0.42), 7)
	var pad := _pad(12)
	panel.add_child(pad)
	var box := UiFactory.vbox(2)
	pad.add_child(box)
	box.add_child(UiFactory.label(value, 24, Color(0.93, 0.99, 1.0)))
	box.add_child(UiFactory.label(label_text, 13, Color(0.65, 0.75, 0.78)))
	return panel

func _status_chip(text: String) -> PanelContainer:
	var chip := _panel(Color(0.04, 0.07, 0.08, 0.68), Color(0.50, 0.70, 0.78, 0.34), 6)
	var pad := _pad(8)
	chip.add_child(pad)
	pad.add_child(UiFactory.label(text, 13, Color(0.75, 0.86, 0.88)))
	return chip

func _add_scrim(color: Color) -> void:
	var scrim := ColorRect.new()
	UiFactory.fill(scrim)
	scrim.color = color
	add_child(scrim)

func _panel(bg_color: Color, border_color: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _pad(margin_size: int) -> MarginContainer:
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", margin_size)
	pad.add_theme_constant_override("margin_right", margin_size)
	pad.add_theme_constant_override("margin_top", margin_size)
	pad.add_theme_constant_override("margin_bottom", margin_size)
	return pad

func _continue_run() -> void:
	if AppRoot.run_session.restore_from_suspend(AppRoot.save_service.load_suspend()):
		var tag: String = String(AppRoot.run_session.run_state.get("current_scene_tag", "map"))
		if tag == "battle" and not AppRoot.battle_service.restore_battle(AppRoot.run_session.run_state):
			tag = "map"
			AppRoot.run_session.run_state["current_scene_tag"] = "map"
		AppRoot.flow_controller.show_scene(tag)
