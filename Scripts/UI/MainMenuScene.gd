extends Control

const MAIN_BG := "res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png"
const COMPACT_BREAKPOINT := 900.0
const SHORT_BREAKPOINT := 860.0
const BUILD_LABEL := "后端首个可玩"
const MENU_WIDTH := 384.0
const DESKTOP_MARGIN := 44
const COMPACT_MARGIN := 22
const BROADCAST_INTERVAL := 4.2
const SPOTLIGHT_INTERVAL := 5.0

const CLASS_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_head_icon_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_head_icon_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_head_icon_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_head_icon_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
}
const CLASS_KEY_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_keyart_v1.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_keyart_v1.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_keyart_v1.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_keyart_v1.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_keyart_v1.png",
}
const CLASS_SHORT_LABELS := {
	"backend": "后端",
	"frontend": "前端",
	"tester": "测试",
	"algorithm": "算法",
	"product_manager": "产品",
}
const CLASS_RESOURCE_LABELS := {
	"backend": "服务 / 缓存",
	"frontend": "组件 / 样式层",
	"tester": "Bug / 用例 / Diff",
	"algorithm": "算力 / 复杂度",
	"product_manager": "需求变更 / 优先级",
}
const MENU_ICONS := {
	"new_run": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-1.png",
	"continue": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-2.png",
	"meta": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-5.png",
	"options": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-4.png",
	"quit": "res://Resources/Art/Generated/P0/icons/node_icon_combat_set_v1/processed/sheet-6.png",
}
const SCENE_LABELS := {
	"map": "楼层路线",
	"battle": "冲突处理中",
	"reward": "战后奖励",
	"shop": "自动贩卖机",
	"event": "随机事件",
	"rest": "茶水间休息",
	"run_result": "复盘结算",
	"class_select": "职业选择",
	"meta": "工位成长",
}
const RESUMABLE_SCENE_TAGS := ["map", "battle", "reward", "shop", "event", "rest", "run_result"]
const BROADCASTS := [
	"楼宇广播：今日电梯优先服务正在爬楼的打工人。",
	"会议室提示：画饼主管已占用 6F，请携带防线入场。",
	"工位小报：窝囊费可在成长页兑换长期体面。",
	"系统提示：当前仅后端开放，其余职业暂在解锁树占位。",
]

var _content_layer: Control
var _rebuild_queued := false
var _ambient_time := 0.0
var _broadcast_timer := 0.0
var _broadcast_index := 0
var _broadcast_label: Label
var _ambient_lines: Array = []
var _pulse_nodes: Array = []
var _menu_buttons: Array = []
var _spotlight_timer := 0.0
var _spotlight_index := 0
var _spotlight_items: Array = []
var _spotlight_art_rect: TextureRect
var _spotlight_name_label: Label
var _spotlight_summary_label: Label
var _spotlight_resource_label: Label
var _spotlight_card_count_label: Label
var _spotlight_difficulty_label: Label
var _spotlight_accent_bar: ColorRect
var _spotlight_start_button: Button
var _spotlight_tab_buttons: Array = []
var _options_overlay: Control
var _master_volume_label: Label
var _app_root_node


func _ready() -> void:
	_app_root()
	_apply_saved_settings()
	UiFactory.fill(self)
	UiFactory.add_background(self, MAIN_BG)
	_add_readability_scrims()
	_add_atmosphere_overlay()
	_content_layer = Control.new()
	_content_layer.name = "MenuContent"
	UiFactory.fill(_content_layer)
	add_child(_content_layer)
	_build_menu()
	get_viewport().size_changed.connect(_queue_rebuild)
	set_process(true)


func _process(delta: float) -> void:
	_ambient_time += delta
	_broadcast_timer += delta
	if _broadcast_label != null and is_instance_valid(_broadcast_label) and _broadcast_timer >= BROADCAST_INTERVAL:
		_broadcast_timer = 0.0
		_broadcast_index = (_broadcast_index + 1) % BROADCASTS.size()
		_broadcast_label.text = String(BROADCASTS[_broadcast_index])
	if not UiMotion.ambient_motion_enabled():
		return
	for index in range(_ambient_lines.size()):
		var line = _ambient_lines[index]
		if not is_instance_valid(line):
			continue
		var alpha := 0.024 + 0.024 * (0.5 + 0.5 * sin(_ambient_time * 1.18 + float(index) * 0.9))
		line.color = Color(line.color.r, line.color.g, line.color.b, alpha)
	for index in range(_pulse_nodes.size()):
		var node = _pulse_nodes[index]
		if not is_instance_valid(node):
			continue
		var pulse := 0.88 + 0.12 * (0.5 + 0.5 * sin(_ambient_time * 1.5 + float(index) * 0.65))
		node.modulate = Color(1, 1, 1, pulse)
	if _spotlight_items.size() > 1:
		_spotlight_timer += delta
		if _spotlight_timer >= SPOTLIGHT_INTERVAL:
			_set_spotlight_index((_spotlight_index + 1) % _spotlight_items.size(), true)


func _unhandled_input(event: InputEvent) -> void:
	if _options_overlay != null and is_instance_valid(_options_overlay) and event.is_action_pressed("ui_cancel"):
		_close_options_panel()
		accept_event()


func _build_menu() -> void:
	if _content_layer == null:
		return
	_pulse_nodes.clear()
	_menu_buttons.clear()
	_broadcast_label = null
	_spotlight_items.clear()
	_spotlight_art_rect = null
	_spotlight_name_label = null
	_spotlight_summary_label = null
	_spotlight_resource_label = null
	_spotlight_card_count_label = null
	_spotlight_difficulty_label = null
	_spotlight_accent_bar = null
	_spotlight_start_button = null
	_spotlight_tab_buttons.clear()
	for child in _content_layer.get_children():
		_content_layer.remove_child(child)
		child.queue_free()

	if _is_compact_layout():
		_build_compact_menu()
	else:
		_build_desktop_menu()


func _build_desktop_menu() -> void:
	var margin := _root_margin(DESKTOP_MARGIN)
	_content_layer.add_child(margin)

	var root := UiFactory.hbox(36)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var left := UiFactory.vbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	left.add_child(_top_bar(false))
	var left_spacer := Control.new()
	left_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_spacer)
	left.add_child(_hero_block(false))
	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(1, 34)
	left.add_child(bottom_pad)

	var menu_wrap := CenterContainer.new()
	menu_wrap.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	menu_wrap.size_flags_horizontal = Control.SIZE_SHRINK_END
	menu_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(menu_wrap)

	var menu := _menu_panel(false)
	menu.custom_minimum_size = Vector2(MENU_WIDTH, 468)
	menu_wrap.add_child(menu)


func _build_compact_menu() -> void:
	var scroll := ScrollContainer.new()
	UiFactory.fill(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_layer.add_child(scroll)

	var margin := _root_margin(COMPACT_MARGIN)
	scroll.add_child(margin)

	var root := UiFactory.vbox(18)
	var viewport_size := get_viewport_rect().size
	root.custom_minimum_size = Vector2(maxf(320.0, viewport_size.x - float(COMPACT_MARGIN * 2)), 0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	root.add_child(_top_bar(true))
	root.add_child(_hero_block(true))

	var menu := _menu_panel(true)
	menu.custom_minimum_size = Vector2(0, 430)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(menu)


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_menu")


func _rebuild_menu() -> void:
	_rebuild_queued = false
	_build_menu()


func _is_compact_layout() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.x < COMPACT_BREAKPOINT or viewport_size.y < SHORT_BREAKPOINT


func _root_margin(margin_size: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "Root"
	UiFactory.fill(margin)
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	return margin


func _top_bar(compact := false) -> Control:
	var row := UiFactory.hbox(10)
	row.name = "TopBar"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(_status_chip(BUILD_LABEL))
	row.add_child(_status_chip("%d 可开 / %d 占位" % [_playable_class_count(), _placeholder_class_count(false)]))
	if not compact:
		row.add_child(_status_chip("三章爬楼"))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_risk_chip(compact))
	return row


func _hero_block(compact := false) -> Control:
	var box := UiFactory.vbox(12 if compact else 14)
	box.name = "TitlePanel"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := _label("withgai", 56 if compact else 64, Color(0.96, 0.99, 1.0))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.94))
	title.custom_minimum_size = Vector2(320, 70 if compact else 82)
	box.add_child(title)

	var subtitle := _label("写字楼爬楼卡牌肉鸽", 21 if compact else 22, Color(0.90, 0.96, 0.97))
	subtitle.add_theme_constant_override("outline_size", 3)
	subtitle.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.94))
	subtitle.custom_minimum_size = Vector2(320, 30)
	box.add_child(subtitle)

	var copy := _label("抽牌、加班、甩锅，一路爬到总裁办公室。", 16 if compact else 17, Color(0.74, 0.84, 0.86))
	copy.custom_minimum_size = Vector2(320, 28)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(copy)

	var broadcast := _broadcast_strip(compact)
	broadcast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(broadcast)

	var spotlight := _spotlight_panel(compact)
	spotlight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(spotlight)

	var shift_board := _shift_board_panel(compact)
	shift_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(shift_board)

	var route := _route_panel(compact)
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(route)

	var dossier := _career_dossier_strip(compact)
	dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(dossier)
	return box


func _menu_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.025, 0.040, 0.050, 0.91), Color(0.53, 0.83, 0.86, 0.68), 8)
	panel.name = "PrimaryActions"
	var pad := _pad(20 if compact else 24)
	panel.add_child(pad)

	var box := UiFactory.vbox(13)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var title := _label("今晚从哪开工？", 25 if compact else 27, Color(0.95, 0.99, 1.0))
	title.custom_minimum_size = Vector2(260, 34)
	box.add_child(title)

	var copy := _label("用后端开局、接着打，或者先去工位树垫点底气。", 14, Color(0.67, 0.78, 0.80))
	copy.custom_minimum_size = Vector2(260, 44)
	box.add_child(copy)

	var briefing := _menu_briefing_panel(compact)
	briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(briefing)

	var badges := _playable_class_badge_row(compact)
	badges.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(badges)

	var button_gap := Control.new()
	button_gap.custom_minimum_size = Vector2(1, 4)
	box.add_child(button_gap)

	var actions := UiFactory.vbox(10)
	actions.name = "PrimaryActionButtons"
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(actions)

	var new_button := _menu_button("开始爬楼", true, "new_run")
	new_button.name = "NewGameButton"
	new_button.tooltip_text = "进入职业选择界面"
	new_button.pressed.connect(func(): _show_scene("class_select"))
	actions.add_child(new_button)
	new_button.call_deferred("grab_focus")

	var continue_button := _menu_button(_continue_button_text(), false, "continue")
	continue_button.name = "ContinueButton"
	continue_button.disabled = not _has_valid_suspend()
	continue_button.tooltip_text = "从最近一次中断的楼层继续" if not continue_button.disabled else "当前没有可恢复的中断档"
	continue_button.pressed.connect(_continue_run)
	actions.add_child(continue_button)

	var meta_button := _menu_button("工位成长", false, "meta")
	meta_button.name = "MetaButton"
	meta_button.tooltip_text = "打开局外成长和职业解锁树"
	meta_button.pressed.connect(func(): _show_scene("meta"))
	actions.add_child(meta_button)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)

	box.add_child(_save_status_card())

	var options_button := _menu_button("设置", false, "options")
	options_button.name = "OptionsButton"
	options_button.tooltip_text = "调整窗口模式和主音量"
	options_button.pressed.connect(_open_options_panel)
	box.add_child(options_button)

	var quit_button := _menu_button("退出游戏", false, "quit")
	quit_button.name = "ExitButton"
	quit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(quit_button)
	UiMotion.bind_buttons(panel, Color(0.54, 0.88, 0.88))
	call_deferred("_animate_menu_entry")
	return panel


func _save_status_card() -> PanelContainer:
	var panel := _panel(Color(0.03, 0.055, 0.065, 0.78), Color(0.38, 0.62, 0.68, 0.46), 7)
	panel.name = "SaveStatusCard"
	var pad := _pad(14)
	panel.add_child(pad)

	var box := UiFactory.vbox(5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var app = _app_root()
	var meta: Dictionary = {}
	if app != null and app.meta_service != null:
		meta = app.meta_service.meta_state
	var currency := int(meta.get("owned_discomfort_currency", 0))
	var floor_record := int(meta.get("highest_floor_reached", 1))
	box.add_child(_label("当前存档", 16, Color(0.86, 0.95, 0.98)))

	var line := "没有中断档"
	var detail := "新开一局会从 1F 前台重新排队。"
	var suspend: Dictionary = {}
	if app != null and app.save_service != null and app.save_service.has_suspend():
		suspend = app.save_service.load_suspend()
	var run_state := _suspend_run_state(suspend)
	if not run_state.is_empty():
		var career_name := _class_name(String(run_state.get("selected_class_id", "")))
		var scene_tag := String(run_state.get("current_scene_tag", suspend.get("scene_tag", "map")))
		line = "%s / %dF / %s" % [career_name, int(run_state.get("current_floor", 1)), _scene_label(scene_tag)]
		detail = _format_save_time(int(suspend.get("timestamp", 0)))

	var line_label := _label(line, 14, Color(0.73, 0.84, 0.86))
	line_label.custom_minimum_size = Vector2(250, 22)
	box.add_child(line_label)
	var detail_label := _label(detail, 12, Color(0.56, 0.67, 0.70))
	detail_label.custom_minimum_size = Vector2(250, 20)
	box.add_child(detail_label)
	box.add_child(_record_row("窝囊费", str(currency)))
	box.add_child(_record_row("最高楼层", "%dF" % floor_record))
	return panel


func _menu_briefing_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.032, 0.056, 0.064, 0.78), Color(0.52, 0.82, 0.82, 0.44), 7)
	panel.name = "MainMenuBriefingPanel"
	var pad := _pad(11 if compact else 12)
	panel.add_child(pad)

	var box := UiFactory.vbox(5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var header := UiFactory.hbox(8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header)
	header.add_child(_nowrap_label("值班简报", 15, Color(0.88, 0.97, 1.0), 72))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_nowrap_label("今晚", 12, Color(0.62, 0.76, 0.78), 34))

	box.add_child(_briefing_line("本班目标", "从 1F 爬到顶层"))
	box.add_child(_briefing_line("值班职业", "%d 可出战 / %d 占位" % [_playable_class_count(), _placeholder_class_count(false)]))
	box.add_child(_briefing_line("当前风险", String(_risk_state().get("label", "稳定"))))
	return panel


func _briefing_line(label_text: String, value_text: String) -> Control:
	var row := UiFactory.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := _label(label_text, 12, Color(0.60, 0.74, 0.77))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2(64, 19)
	row.add_child(label)
	var value := _label(value_text, 12, Color(0.82, 0.94, 0.95))
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.clip_text = true
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.custom_minimum_size = Vector2(144, 19)
	row.add_child(value)
	return row


func _broadcast_strip(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.025, 0.055, 0.065, 0.70), Color(0.48, 0.78, 0.82, 0.42), 7)
	panel.name = "BroadcastStrip"
	var pad := _pad(12 if compact else 14)
	panel.add_child(pad)

	var row := UiFactory.hbox(10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(row)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.color = Color(0.58, 0.96, 0.86, 0.95)
	row.add_child(dot)
	_pulse_nodes.append(dot)

	_broadcast_label = _label(String(BROADCASTS[_broadcast_index]), 13 if compact else 14, Color(0.80, 0.93, 0.94))
	_broadcast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_broadcast_label.custom_minimum_size = Vector2(260, 24)
	_broadcast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_broadcast_label)
	return panel


func _spotlight_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.026, 0.045, 0.052, 0.82), Color(0.50, 0.82, 0.82, 0.46), 7)
	panel.name = "ClassSpotlightPanel"
	var pad := _pad(14)
	panel.add_child(pad)

	var narrow := compact and get_viewport_rect().size.x < 620
	var root: Container
	if narrow:
		root = UiFactory.vbox(12)
	else:
		root = UiFactory.hbox(14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(root)

	var art_frame := _panel(Color(0.04, 0.060, 0.066, 0.84), Color(0.55, 0.80, 0.82, 0.48), 7)
	art_frame.name = "SpotlightArtFrame"
	art_frame.custom_minimum_size = Vector2(206 if narrow else 238, 164 if narrow else 184)
	art_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_SHRINK_BEGIN
	root.add_child(art_frame)

	var art_pad := _pad(8)
	art_frame.add_child(art_pad)
	_spotlight_art_rect = TextureRect.new()
	_spotlight_art_rect.name = "SpotlightClassArt"
	_spotlight_art_rect.custom_minimum_size = Vector2(190 if narrow else 222, 148 if narrow else 168)
	_spotlight_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_spotlight_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_pad.add_child(_spotlight_art_rect)

	var info := UiFactory.vbox(8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(info)

	var header := UiFactory.hbox(8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(header)

	_spotlight_accent_bar = ColorRect.new()
	_spotlight_accent_bar.custom_minimum_size = Vector2(5, 30)
	header.add_child(_spotlight_accent_bar)

	var title_box := UiFactory.vbox(1)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_label("今日值班职业", 11, Color(0.62, 0.76, 0.78)))
	_spotlight_name_label = _label("", 22 if compact else 25, Color(0.95, 1.0, 1.0))
	_spotlight_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_spotlight_name_label.clip_text = true
	_spotlight_name_label.custom_minimum_size = Vector2(190, 30)
	title_box.add_child(_spotlight_name_label)

	_spotlight_summary_label = _label("", 12 if compact else 13, Color(0.72, 0.84, 0.86))
	_spotlight_summary_label.custom_minimum_size = Vector2(220, 38 if compact else 42)
	_spotlight_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_spotlight_summary_label)

	var stats := UiFactory.hbox(7)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(stats)
	_spotlight_resource_label = _spotlight_chip("资源", "")
	_spotlight_card_count_label = _spotlight_chip("牌池", "")
	_spotlight_difficulty_label = _spotlight_chip("难度", "")
	stats.add_child(_spotlight_resource_label)
	stats.add_child(_spotlight_card_count_label)
	stats.add_child(_spotlight_difficulty_label)

	var tabs := UiFactory.hbox(6)
	tabs.name = "SpotlightClassTabs"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(tabs)

	_spotlight_items = _playable_class_preview_items()
	for index in range(_spotlight_items.size()):
		var item: Dictionary = _spotlight_items[index]
		var tab := Button.new()
		tab.name = "SpotlightTab%s" % String(item.get("id", "")).capitalize()
		tab.text = String(item.get("short_name", item.get("name", "")))
		tab.custom_minimum_size = Vector2(48, 32)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 12)
		tab.add_theme_color_override("font_color", Color(0.88, 0.96, 0.98))
		tab.add_theme_color_override("font_hover_color", Color(0.98, 1.0, 1.0))
		var captured_index := index
		tab.pressed.connect(func(): _set_spotlight_index(captured_index, true))
		_spotlight_tab_buttons.append(tab)
		tabs.add_child(tab)

	_spotlight_start_button = _spotlight_start_button_control()
	info.add_child(_spotlight_start_button)

	if _spotlight_items.is_empty():
		_spotlight_items.append({
			"id": "",
			"name": "职业数据加载中",
			"short_name": "加载中",
			"color": Color(0.58, 0.86, 0.86),
			"art": "",
			"key_art": "",
			"summary": "等待配置表完成加载。",
			"difficulty": 1,
			"resource_label": "资源",
		})
	_spotlight_index = clampi(_spotlight_index, 0, max(0, _spotlight_items.size() - 1))
	_set_spotlight_index(_spotlight_index, false)
	return panel


func _spotlight_chip(label_text: String, value_text: String) -> Label:
	var label := _label("%s %s" % [label_text, value_text], 11, Color(0.80, 0.92, 0.94))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2(70, 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _playable_class_preview_items() -> Array:
	var items: Array = []
	var app = _app_root()
	if app == null or app.config_service == null:
		return items
	for cls in app.config_service.first_playable_classes(false):
		if bool(cls.get("enabled_in_first_playable", false)):
			items.append(_class_preview_item(cls))
	return items

func _career_roster_items(include_hr := true) -> Array:
	var items: Array = []
	var app = _app_root()
	if app == null or app.config_service == null:
		return items
	for cls in app.config_service.first_playable_classes(true):
		if not include_hr and String(cls.get("id", "")) == "hr":
			continue
		items.append(_class_preview_item(cls))
	return items


func _set_spotlight_index(index: int, reset_timer := false) -> void:
	if _spotlight_items.is_empty():
		return
	if reset_timer:
		_spotlight_timer = 0.0
	_spotlight_index = clampi(index, 0, _spotlight_items.size() - 1)
	var item: Dictionary = _spotlight_items[_spotlight_index]
	var accent: Color = item.get("color", Color(0.58, 0.86, 0.86))
	var class_id := String(item.get("id", ""))

	if _spotlight_accent_bar != null and is_instance_valid(_spotlight_accent_bar):
		_spotlight_accent_bar.color = accent
	if _spotlight_name_label != null and is_instance_valid(_spotlight_name_label):
		_spotlight_name_label.text = String(item.get("name", ""))
		_spotlight_name_label.add_theme_color_override("font_color", accent.lightened(0.24))
	if _spotlight_summary_label != null and is_instance_valid(_spotlight_summary_label):
		_spotlight_summary_label.text = String(item.get("summary", ""))
	if _spotlight_resource_label != null and is_instance_valid(_spotlight_resource_label):
		_spotlight_resource_label.text = "资源 %s" % String(item.get("resource_label", ""))
	if _spotlight_card_count_label != null and is_instance_valid(_spotlight_card_count_label):
		_spotlight_card_count_label.text = "牌池 %d" % _class_card_count(class_id)
	if _spotlight_difficulty_label != null and is_instance_valid(_spotlight_difficulty_label):
		_spotlight_difficulty_label.text = "难度 %s" % _difficulty_marks(int(item.get("difficulty", 1)))
	if _spotlight_start_button != null and is_instance_valid(_spotlight_start_button):
		var short_name := String(item.get("short_name", item.get("name", "职业")))
		_spotlight_start_button.text = "用%s开局" % short_name
		_spotlight_start_button.disabled = not _can_start_class(class_id)
		_spotlight_start_button.tooltip_text = "直接创建新局并进入 1F 路线" if not _spotlight_start_button.disabled else "该职业当前不可出战"
	if _spotlight_art_rect != null and is_instance_valid(_spotlight_art_rect):
		var art_path := String(item.get("key_art", ""))
		var texture = load(art_path) if not art_path.is_empty() else null
		if texture == null:
			art_path = String(item.get("art", ""))
			texture = load(art_path) if not art_path.is_empty() else null
		_spotlight_art_rect.texture = texture
		_spotlight_art_rect.modulate = Color(1, 1, 1, 0.95 if texture != null else 0.45)

	for tab_index in range(_spotlight_tab_buttons.size()):
		var tab: Button = _spotlight_tab_buttons[tab_index]
		if not is_instance_valid(tab):
			continue
		var tab_item: Dictionary = _spotlight_items[tab_index]
		var tab_accent: Color = tab_item.get("color", accent)
		var active := tab_index == _spotlight_index
		tab.add_theme_stylebox_override("normal", _spotlight_tab_style(active, tab_accent, false))
		tab.add_theme_stylebox_override("hover", _spotlight_tab_style(active, tab_accent, true))
		tab.add_theme_stylebox_override("pressed", _spotlight_tab_style(true, tab_accent, true))
		tab.add_theme_stylebox_override("focus", _spotlight_tab_style(true, tab_accent, true))


func _spotlight_tab_style(active: bool, accent: Color, hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.046, 0.066, 0.072, 0.86)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.36)
	if active:
		style.bg_color = Color(accent.r * 0.32, accent.g * 0.32, accent.b * 0.32, 0.94)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.82)
	if hover:
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = style.border_color.lightened(0.10)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _spotlight_start_button_control() -> Button:
	var button := Button.new()
	button.name = "SpotlightStartButton"
	button.custom_minimum_size = Vector2(180, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.94, 0.99, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.50, 0.58, 0.60))
	button.add_theme_stylebox_override("normal", _spotlight_cta_style(false, false))
	button.add_theme_stylebox_override("hover", _spotlight_cta_style(false, true))
	button.add_theme_stylebox_override("pressed", _spotlight_cta_style(true, true))
	button.add_theme_stylebox_override("focus", _spotlight_cta_style(true, true))
	button.add_theme_stylebox_override("disabled", _spotlight_cta_disabled_style())
	button.pressed.connect(_start_spotlight_class)
	return button


func _spotlight_cta_style(active: bool, hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.34, 0.35, 0.92)
	style.border_color = Color(0.54, 0.94, 0.88, 0.76)
	if active:
		style.bg_color = Color(0.10, 0.42, 0.42, 0.96)
	if hover:
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = style.border_color.lightened(0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style


func _spotlight_cta_disabled_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.11, 0.72)
	style.border_color = Color(0.28, 0.34, 0.36, 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style


func _shift_board_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.026, 0.044, 0.052, 0.76), Color(0.50, 0.80, 0.82, 0.42), 7)
	panel.name = "ShiftBoardPanel"
	var pad := _pad(14)
	panel.add_child(pad)

	var box := UiFactory.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var header := UiFactory.hbox(8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header)
	header.add_child(_nowrap_label("值班看板", 15, Color(0.88, 0.97, 1.0), 72))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_nowrap_label("首屏状态", 12, Color(0.60, 0.74, 0.78), 62))

	var stats: Container
	var narrow := compact and get_viewport_rect().size.x < 560
	if narrow:
		var grid := GridContainer.new()
		grid.columns = 1
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		stats = grid
	else:
		stats = UiFactory.hbox(8)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(stats)

	stats.add_child(_shift_stat("可选职业", "%d" % _playable_class_count(), "后端全链路优先", Color(0.42, 0.88, 0.82)))
	stats.add_child(_shift_stat("中断档", "有" if _has_valid_suspend() else "无", _save_resume_summary(), Color(0.96, 0.72, 0.36)))
	stats.add_child(_shift_stat("窝囊费", str(_meta_currency()), "局外成长资源", Color(0.70, 0.62, 0.96)))
	return panel


func _shift_stat(label_text: String, value_text: String, detail_text: String, accent: Color) -> PanelContainer:
	var panel := _panel(Color(0.04, 0.064, 0.072, 0.78), Color(accent.r, accent.g, accent.b, 0.42), 6)
	panel.custom_minimum_size = Vector2(148, 70)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := _pad(9)
	panel.add_child(pad)

	var box := UiFactory.vbox(2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)
	box.add_child(_label(label_text, 11, Color(0.62, 0.76, 0.78)))
	var value := _label(value_text, 22, Color(accent.r, accent.g, accent.b, 1.0))
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.clip_text = true
	value.custom_minimum_size = Vector2(64, 26)
	box.add_child(value)
	var detail := _label(detail_text, 11, Color(0.70, 0.82, 0.84))
	detail.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail.clip_text = true
	detail.custom_minimum_size = Vector2(96, 18)
	box.add_child(detail)
	return panel


func _route_panel(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.028, 0.045, 0.050, 0.78), Color(0.50, 0.76, 0.80, 0.40), 7)
	panel.name = "RoutePreviewPanel"
	var pad := _pad(14)
	panel.add_child(pad)

	var box := UiFactory.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var header := UiFactory.hbox(8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header)
	header.add_child(_nowrap_label("今晚路线", 15, Color(0.88, 0.97, 1.0), 72))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_nowrap_label("16-20 个节点", 12, Color(0.60, 0.74, 0.78), 88))

	var route: Container
	if compact and get_viewport_rect().size.x < 560:
		route = UiFactory.vbox(8)
	else:
		route = UiFactory.hbox(8)
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(route)

	route.add_child(_route_stop("1F-6F", "基层办公区", "画饼主管", Color(0.32, 0.78, 0.74)))
	route.add_child(_route_stop("7F-12F", "中层管理区", "变异 HR", Color(0.96, 0.68, 0.34)))
	route.add_child(_route_stop("13F-顶层", "总裁区", "变异总裁", Color(0.68, 0.58, 0.98)))
	return panel


func _route_stop(floor_text: String, area_text: String, boss_text: String, accent: Color) -> PanelContainer:
	var panel := _panel(Color(0.05, 0.07, 0.075, 0.80), Color(accent.r, accent.g, accent.b, 0.42), 6)
	panel.custom_minimum_size = Vector2(160, 76)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := _pad(9)
	panel.add_child(pad)

	var box := UiFactory.vbox(2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)
	box.add_child(_label(floor_text, 14, Color(accent.r, accent.g, accent.b, 1.0)))
	box.add_child(_label(area_text, 13, Color(0.88, 0.96, 0.98)))
	var boss := _label(boss_text, 11, Color(0.60, 0.72, 0.76))
	boss.autowrap_mode = TextServer.AUTOWRAP_OFF
	boss.clip_text = true
	box.add_child(boss)
	return panel


func _career_dossier_strip(compact := false) -> Control:
	var row: Container
	if compact:
		var grid := GridContainer.new()
		grid.columns = 1 if get_viewport_rect().size.x < 560 else 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		row = grid
	else:
		row = UiFactory.hbox(10)
	row.name = "CareerDossierStrip"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for item in _playable_class_preview_items():
		row.add_child(_class_dossier(item, compact))
	return row


func _playable_class_badge_row(compact := false) -> PanelContainer:
	var panel := _panel(Color(0.030, 0.052, 0.058, 0.74), Color(0.48, 0.76, 0.80, 0.42), 7)
	panel.name = "PlayableClassBadges"
	var pad := _pad(8)
	panel.add_child(pad)

	var row := UiFactory.hbox(5 if compact else 6)
	row.name = "ClassBadgeRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(row)

	var items := _career_roster_items(false)
	if items.is_empty():
		row.add_child(_label("职业数据加载中", 12, Color(0.68, 0.80, 0.82)))
		return panel

	for item in items:
		row.add_child(_class_badge_chip(item, compact))
	return panel


func _class_badge_chip(item: Dictionary, compact := false) -> PanelContainer:
	var accent: Color = item.get("color", Color(0.58, 0.86, 0.86))
	var available := bool(item.get("available", false))
	var chip_bg := Color(0.042, 0.064, 0.070, 0.88) if available else Color(0.034, 0.044, 0.048, 0.82)
	var border_alpha := 0.50 if available else 0.24
	var chip := _panel(chip_bg, Color(accent.r, accent.g, accent.b, border_alpha), 6)
	chip.custom_minimum_size = Vector2(42 if compact else 46, 62)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.tooltip_text = "%s / %s" % [String(item.get("name", "")), String(item.get("availability", ""))]

	var pad := _pad(5)
	chip.add_child(pad)
	var box := UiFactory.vbox(2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var portrait := _class_badge_portrait(item, accent)
	portrait.custom_minimum_size = Vector2(30, 30)
	portrait.modulate = Color(1, 1, 1, 0.96 if available else 0.42)
	box.add_child(portrait)

	var label_color := Color(0.84, 0.94, 0.96) if available else Color(0.48, 0.58, 0.60)
	var label := _label(String(item.get("short_name", "")), 11, label_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2(34, 18)
	box.add_child(label)
	return chip


func _class_badge_portrait(item: Dictionary, accent: Color) -> Control:
	var art_path := String(item.get("art", ""))
	if not art_path.is_empty():
		var portrait := UiFactory.texture(art_path, Vector2(30, 30))
		portrait.modulate = Color(1, 1, 1, 0.96)
		return portrait
	var fallback := _panel(accent.darkened(0.42), accent.lightened(0.12), 6)
	fallback.custom_minimum_size = Vector2(30, 30)
	var center := CenterContainer.new()
	fallback.add_child(center)
	var display_name := String(item.get("name", "?"))
	center.add_child(_label(display_name.substr(0, 1), 14, Color(0.93, 0.98, 0.94)))
	return fallback


func _class_dossier(item: Dictionary, compact := false) -> PanelContainer:
	var accent: Color = item.get("color", Color.WHITE)
	var panel := _panel(Color(0.035, 0.055, 0.065, 0.78), Color(accent.r, accent.g, accent.b, 0.50), 7)
	panel.custom_minimum_size = Vector2(232 if compact else 218, 112)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN

	var pad := _pad(10)
	panel.add_child(pad)
	var box := UiFactory.vbox(6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var row := UiFactory.hbox(9)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)

	var portrait := _class_portrait(item, accent)
	portrait.custom_minimum_size = Vector2(42, 42)
	row.add_child(portrait)

	var title_box := UiFactory.vbox(1)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)

	var name_label := _label(String(item.get("short_name", item.get("name", ""))), 15, Color(0.92, 0.98, 1.0))
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.custom_minimum_size = Vector2(92, 20)
	name_label.clip_text = true
	title_box.add_child(name_label)

	var resource_label := _label(String(item.get("resource_label", "")), 11, Color(0.62, 0.75, 0.78))
	resource_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	resource_label.clip_text = true
	resource_label.custom_minimum_size = Vector2(114, 18)
	title_box.add_child(resource_label)

	var summary := _label(String(item.get("summary", "")), 11, Color(0.70, 0.82, 0.84))
	summary.custom_minimum_size = Vector2(176, 30)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(summary)

	var metrics := UiFactory.hbox(6)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(metrics)
	metrics.add_child(_metric_chip("难度", _difficulty_marks(int(item.get("difficulty", 1))), accent))
	metrics.add_child(_metric_chip("牌池", str(_class_card_count(String(item.get("id", "")))), accent))
	return panel


func _class_preview_item(cls: Dictionary) -> Dictionary:
	var class_id := String(cls.get("id", ""))
	var available := _can_start_class(class_id)
	var availability := "可出战" if available else ("扩展占位" if class_id == "hr" else "锁定占位")
	var app = _app_root()
	if app != null and app.meta_service != null:
		availability = app.meta_service.class_availability_label(cls)
	return {
		"id": class_id,
		"name": String(cls.get("name", class_id)),
		"short_name": String(CLASS_SHORT_LABELS.get(class_id, cls.get("name", class_id))),
		"color": Color(String(cls.get("color", "#ffffff"))),
		"art": String(CLASS_ART.get(class_id, "")),
		"key_art": String(CLASS_KEY_ART.get(class_id, "")),
		"summary": String(cls.get("summary", "")),
		"difficulty": int(cls.get("recommended_difficulty", 1)),
		"resource_label": String(CLASS_RESOURCE_LABELS.get(class_id, "")),
		"available": available,
		"availability": availability,
	}


func _class_portrait(item: Dictionary, accent: Color) -> Control:
	var art_path := String(item.get("art", ""))
	if not art_path.is_empty():
		var portrait := UiFactory.texture(art_path, Vector2(38, 38))
		portrait.modulate = Color(1, 1, 1, 0.96)
		return portrait
	var fallback := _panel(accent.darkened(0.42), accent.lightened(0.12), 7)
	fallback.custom_minimum_size = Vector2(38, 38)
	var center := CenterContainer.new()
	fallback.add_child(center)
	var display_name := String(item.get("name", "?"))
	center.add_child(_label(display_name.substr(0, 1), 18, Color(0.93, 0.98, 0.94)))
	return fallback


func _menu_button(text: String, primary := false, icon_key := "") -> Button:
	var button := Button.new()
	button.text = text
	_menu_buttons.append(button)
	button.custom_minimum_size = Vector2(260, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.55, 0.57))
	button.add_theme_color_override("icon_normal_color", Color(0.92, 0.98, 1.0))
	button.add_theme_color_override("icon_disabled_color", Color(0.48, 0.55, 0.57))

	var icon := _load_menu_icon(icon_key)
	if icon != null:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var normal := _button_style(primary, false)
	var hover := _button_style(primary, true)
	var disabled := _button_style(false, false)
	disabled.bg_color = Color(0.10, 0.12, 0.13, 0.70)
	disabled.border_color = Color(0.30, 0.36, 0.38, 0.42)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	return button


func _metric_chip(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var chip := _panel(Color(0.025, 0.042, 0.048, 0.76), Color(accent.r, accent.g, accent.b, 0.36), 5)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := _pad(5)
	chip.add_child(pad)
	var label := _label("%s %s" % [label_text, value_text], 10, Color(0.78, 0.90, 0.92))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2(56, 18)
	pad.add_child(label)
	return chip


func _load_menu_icon(icon_key: String) -> Texture2D:
	var icon_path := String(MENU_ICONS.get(icon_key, ""))
	if icon_path.is_empty():
		return null
	var source_texture := load(icon_path) as Texture2D
	if source_texture == null:
		return null
	var image := source_texture.get_image()
	if image == null:
		return source_texture
	image.resize(30, 30, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _button_style(primary: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.105, 0.120, 0.94)
	style.border_color = Color(0.44, 0.62, 0.68, 0.60)
	if primary:
		style.bg_color = Color(0.09, 0.45, 0.46, 0.96)
		style.border_color = Color(0.56, 0.96, 0.91, 0.88)
	if hover:
		style.bg_color = style.bg_color.lightened(0.08)
		style.border_color = style.border_color.lightened(0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


func _record_row(label_text: String, value_text: String) -> Control:
	var label := _label("%s  %s" % [label_text, value_text], 13, Color(0.80, 0.91, 0.93))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2(250, 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _status_chip(text: String) -> PanelContainer:
	var chip := _panel(Color(0.04, 0.07, 0.08, 0.70), Color(0.50, 0.72, 0.78, 0.42), 6)
	var pad := _pad(8)
	chip.add_child(pad)
	var label := _label(text, 12, Color(0.75, 0.86, 0.88))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2(maxf(62.0, float(text.length()) * 14.0), 18)
	label.clip_text = true
	pad.add_child(label)
	return chip


func _risk_chip(compact := false) -> PanelContainer:
	var risk_state := _risk_state()
	var risk := String(risk_state.get("label", "稳定"))
	var accent: Color = risk_state.get("accent", Color(0.58, 0.96, 0.82))
	var chip := _panel(Color(0.04, 0.07, 0.08, 0.70), Color(accent.r, accent.g, accent.b, 0.48), 6)
	var pad := _pad(8)
	chip.add_child(pad)
	var label := _label("KPI风险 %s" % risk, 12 if compact else 13, Color(accent.r, accent.g, accent.b, 0.94))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2(92, 18)
	label.clip_text = true
	pad.add_child(label)
	return chip


func _risk_state() -> Dictionary:
	var risk := "稳定"
	var accent := Color(0.58, 0.96, 0.82)
	var app = _app_root()
	var suspend: Dictionary = {}
	if app != null and app.save_service != null and app.save_service.has_suspend():
		suspend = app.save_service.load_suspend()
	var run_state := _suspend_run_state(suspend)
	if not run_state.is_empty():
		var hp := int(run_state.get("current_hp", run_state.get("player_hp", 72)))
		var current_floor := int(run_state.get("current_floor", 1))
		if hp <= 24 or current_floor >= 13:
			risk = "偏高"
			accent = Color(0.98, 0.58, 0.44)
		elif hp <= 42 or current_floor >= 7:
			risk = "攀升"
			accent = Color(0.94, 0.76, 0.38)
	return {
		"label": risk,
		"accent": accent,
	}


func _label(text: String, font_size := 18, color := Color.WHITE) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _nowrap_label(text: String, font_size := 18, color := Color.WHITE, min_width := 0.0) -> Label:
	var label := _label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	if min_width > 0.0:
		label.custom_minimum_size = Vector2(min_width, font_size + 8)
	return label


func _app_root():
	if _app_root_node != null and is_instance_valid(_app_root_node):
		return _app_root_node
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	_app_root_node = tree.root.get_node_or_null("AppRoot")
	if _app_root_node != null and _app_root_node.has_method("boot"):
		_app_root_node.call("boot")
	return _app_root_node


func _show_scene(tag: String) -> void:
	var app = _app_root()
	if app != null and app.flow_controller != null:
		app.flow_controller.show_scene(tag)


func _playable_class_count() -> int:
	var count := 0
	var app = _app_root()
	if app == null or app.config_service == null:
		return count
	for cls in app.config_service.first_playable_classes(false):
		if bool(cls.get("enabled_in_first_playable", false)):
			count += 1
	return count

func _placeholder_class_count(include_hr := true) -> int:
	var count := 0
	var app = _app_root()
	if app == null or app.config_service == null:
		return count
	for cls in app.config_service.first_playable_classes(true):
		var class_id := String(cls.get("id", ""))
		if not include_hr and class_id == "hr":
			continue
		if not _can_start_class(class_id):
			count += 1
	return count


func _meta_currency() -> int:
	var app = _app_root()
	if app == null or app.meta_service == null:
		return 0
	return int(app.meta_service.meta_state.get("owned_discomfort_currency", 0))


func _continue_button_text() -> String:
	var run_state := _suspend_run_state()
	if run_state.is_empty():
		return "没有中断档"
	return "继续 %s %dF" % [
		CLASS_SHORT_LABELS.get(String(run_state.get("selected_class_id", "")), "未知"),
		int(run_state.get("current_floor", 1)),
	]


func _save_resume_summary() -> String:
	var run_state := _suspend_run_state()
	if run_state.is_empty():
		return "新局从 1F 开始"
	return _scene_label(String(run_state.get("current_scene_tag", "map")))


func _class_card_count(class_id: String) -> int:
	var app = _app_root()
	if class_id.is_empty() or app == null or app.config_service == null:
		return 0
	return app.config_service.cards_for_class(class_id, true).size()


func _difficulty_marks(value: int) -> String:
	var filled := clampi(value, 1, 5)
	var marks := ""
	for index in range(5):
		marks += "■" if index < filled else "□"
	return marks


func _has_valid_suspend() -> bool:
	return not _suspend_run_state().is_empty()


func _can_start_class(class_id: String) -> bool:
	var app = _app_root()
	if class_id.is_empty() or app == null or app.meta_service == null:
		return false
	return app.meta_service.is_class_playable(class_id)


func _suspend_run_state(save_state: Dictionary = {}) -> Dictionary:
	if save_state.is_empty():
		var app = _app_root()
		if app == null or app.save_service == null or not app.save_service.has_suspend():
			return {}
		save_state = app.save_service.load_suspend()
	var run_state = save_state.get("serialized_run_state", {})
	return run_state if typeof(run_state) == TYPE_DICTIONARY else {}


func _class_name(class_id: String) -> String:
	var app = _app_root()
	var cls: Dictionary = app.config_service.get_def("classes", class_id) if app != null and app.config_service != null else {}
	return String(cls.get("name", class_id if not class_id.is_empty() else "未知职业"))


func _scene_label(scene_tag: String) -> String:
	return String(SCENE_LABELS.get(scene_tag, scene_tag))


func _format_save_time(timestamp: int) -> String:
	if timestamp <= 0:
		return "保存时间未知"
	var dt := Time.get_datetime_dict_from_unix_time(timestamp)
	return "保存于 %04d-%02d-%02d %02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
	]


func _add_readability_scrims() -> void:
	var base := ColorRect.new()
	UiFactory.fill(base)
	base.color = Color(0.01, 0.015, 0.018, 0.28)
	add_child(base)

	var bottom := ColorRect.new()
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 0.48
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 0
	bottom.offset_right = 0
	bottom.offset_top = 0
	bottom.offset_bottom = 0
	bottom.color = Color(0.01, 0.018, 0.022, 0.42)
	add_child(bottom)

	var right := ColorRect.new()
	right.anchor_left = 0.64
	right.anchor_right = 1.0
	right.anchor_top = 0.0
	right.anchor_bottom = 1.0
	right.offset_left = 0
	right.offset_right = 0
	right.offset_top = 0
	right.offset_bottom = 0
	right.color = Color(0.01, 0.018, 0.022, 0.34)
	add_child(right)


func _add_atmosphere_overlay() -> void:
	var overlay := Control.new()
	UiFactory.fill(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_ambient_lines.clear()

	for index in range(6):
		var x := 0.12 + float(index) * 0.15
		var line := ColorRect.new()
		line.color = Color(0.60, 0.82, 0.88, 0.034)
		line.anchor_left = x
		line.anchor_right = x
		line.anchor_top = 0.0
		line.anchor_bottom = 1.0
		line.offset_right = 1.0
		overlay.add_child(line)
		_ambient_lines.append(line)

	for index in range(4):
		var y := 0.22 + float(index) * 0.18
		var line := ColorRect.new()
		line.color = Color(0.60, 0.82, 0.88, 0.032)
		line.anchor_left = 0.0
		line.anchor_right = 1.0
		line.anchor_top = y
		line.anchor_bottom = y
		line.offset_bottom = 1.0
		overlay.add_child(line)
		_ambient_lines.append(line)


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


func _open_options_panel() -> void:
	_close_options_panel()
	_options_overlay = Control.new()
	_options_overlay.name = "OptionsOverlay"
	_options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	UiFactory.fill(_options_overlay)
	add_child(_options_overlay)

	var scrim := ColorRect.new()
	scrim.name = "OptionsScrim"
	scrim.color = Color(0.006, 0.012, 0.015, 0.62)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	UiFactory.fill(scrim)
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_close_options_panel()
	)
	_options_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "OptionsCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFactory.fill(center)
	_options_overlay.add_child(center)

	var panel := _panel(Color(0.026, 0.044, 0.052, 0.96), Color(0.54, 0.88, 0.88, 0.72), 8)
	panel.name = "OptionsPanel"
	panel.custom_minimum_size = Vector2(430, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var pad := _pad(22)
	panel.add_child(pad)
	var box := UiFactory.vbox(14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(box)

	var header := UiFactory.hbox(10)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header)
	header.add_child(_label("设置", 26, Color(0.94, 0.99, 1.0)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(82, 34)
	close.add_theme_font_size_override("font_size", 13)
	close.pressed.connect(_close_options_panel)
	header.add_child(close)

	var fullscreen := CheckButton.new()
	fullscreen.name = "FullscreenToggle"
	fullscreen.text = "全屏模式"
	fullscreen.button_pressed = get_window().mode == Window.MODE_FULLSCREEN
	fullscreen.add_theme_font_size_override("font_size", 16)
	fullscreen.add_theme_color_override("font_color", Color(0.86, 0.96, 0.98))
	fullscreen.toggled.connect(_set_fullscreen)
	box.add_child(fullscreen)

	var volume_panel := _panel(Color(0.038, 0.060, 0.068, 0.82), Color(0.46, 0.72, 0.76, 0.42), 7)
	volume_panel.name = "AudioOptionsPanel"
	box.add_child(volume_panel)
	var volume_pad := _pad(12)
	volume_panel.add_child(volume_pad)
	var volume_box := UiFactory.vbox(7)
	volume_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_pad.add_child(volume_box)
	_master_volume_label = _label("", 15, Color(0.84, 0.95, 0.97))
	volume_box.add_child(_master_volume_label)
	var slider := HSlider.new()
	slider.name = "MasterVolumeSlider"
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = float(_master_volume_percent())
	slider.custom_minimum_size = Vector2(320, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_set_master_volume)
	volume_box.add_child(slider)
	_refresh_master_volume_label(slider.value)

	var hint := _label("设置会保存到局外档。", 12, Color(0.58, 0.70, 0.73))
	hint.custom_minimum_size = Vector2(320, 22)
	box.add_child(hint)
	box.add_child(_setting_toggle("ReduceMotionToggle", "减少动效", "reduce_motion", false))
	box.add_child(_setting_toggle("AmbientMotionToggle", "背景氛围动效", "ambient_motion", true))
	box.add_child(_setting_toggle("ScreenShakeToggle", "屏幕震动", "screen_shake", false))
	UiMotion.bind_buttons(panel, Color(0.54, 0.88, 0.88))
	UiMotion.fade_in(panel, 0.18, Vector2(0, 16))
	close.call_deferred("grab_focus")


func _close_options_panel() -> void:
	if _options_overlay == null:
		return
	if is_instance_valid(_options_overlay):
		_options_overlay.queue_free()
	_options_overlay = null
	_master_volume_label = null


func _set_fullscreen(enabled: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
	var app = _app_root()
	if app != null and app.meta_service != null:
		app.meta_service.update_setting("fullscreen", enabled)


func _setting_toggle(node_name: String, text: String, key: String, default_value: bool) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.name = node_name
	toggle.text = text
	toggle.button_pressed = bool(_settings_state().get(key, default_value))
	toggle.add_theme_font_size_override("font_size", 15)
	toggle.add_theme_color_override("font_color", Color(0.84, 0.95, 0.97))
	toggle.toggled.connect(func(enabled: bool): _set_bool_setting(key, enabled))
	return toggle


func _set_bool_setting(key: String, enabled: bool) -> void:
	var app = _app_root()
	if app != null and app.meta_service != null:
		app.meta_service.update_setting(key, enabled)


func _set_master_volume(value: float) -> void:
	_apply_master_volume(value)
	var app = _app_root()
	if app != null and app.meta_service != null:
		app.meta_service.update_setting("master_volume", clampi(roundi(value), 0, 100))
	_refresh_master_volume_label(value)


func _apply_saved_settings() -> void:
	var settings := _settings_state()
	get_window().mode = Window.MODE_FULLSCREEN if bool(settings.get("fullscreen", false)) else Window.MODE_WINDOWED
	_apply_master_volume(float(settings.get("master_volume", 100)))


func _apply_master_volume(value: float) -> void:
	var bus := _master_bus_index()
	if value <= 0.0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(value / 100.0, 0.01, 1.0)))


func _settings_state() -> Dictionary:
	var app = _app_root()
	if app == null or app.meta_service == null:
		return {}
	var settings: Dictionary = app.meta_service.meta_state.get("settings", {})
	if settings.is_empty():
		settings = { "fullscreen": false, "master_volume": 100, "reduce_motion": false, "ambient_motion": true, "screen_shake": false }
		app.meta_service.meta_state["settings"] = settings
	return settings


func _animate_menu_entry() -> void:
	if _content_layer == null or not is_instance_valid(_content_layer):
		return
	for node_name in ["TitlePanel", "BroadcastStrip", "ClassSpotlightPanel", "PrimaryActions"]:
		var node := _content_layer.find_child(node_name, true, false)
		if node is CanvasItem:
			UiMotion.fade_in(node, 0.22, Vector2(0, 18))


func _refresh_master_volume_label(value: float) -> void:
	if _master_volume_label == null or not is_instance_valid(_master_volume_label):
		return
	_master_volume_label.text = "主音量 %d%%" % roundi(value)


func _master_volume_percent() -> int:
	var bus := _master_bus_index()
	if AudioServer.is_bus_mute(bus):
		return 0
	var linear := db_to_linear(AudioServer.get_bus_volume_db(bus))
	return clampi(roundi(linear * 100.0), 0, 100)


func _master_bus_index() -> int:
	var bus := AudioServer.get_bus_index("Master")
	return bus if bus >= 0 else 0


func _continue_run() -> void:
	var app = _app_root()
	if app == null or app.run_session == null or app.save_service == null:
		return
	var suspend: Dictionary = app.save_service.load_suspend()
	if app.run_session.restore_from_suspend(suspend):
		var tag := _resume_scene_tag(String(app.run_session.run_state.get("current_scene_tag", suspend.get("scene_tag", "map"))))
		if tag == "battle" and not app.battle_service.restore_battle(app.run_session.run_state):
			tag = "map"
		app.run_session.run_state["current_scene_tag"] = tag
		_show_scene(tag)


func _resume_scene_tag(scene_tag: String) -> String:
	return scene_tag if RESUMABLE_SCENE_TAGS.has(scene_tag) else "map"


func _start_spotlight_class() -> void:
	if _spotlight_items.is_empty():
		return
	var item: Dictionary = _spotlight_items[_spotlight_index]
	_start_class_from_menu(String(item.get("id", "")))


func _start_class_from_menu(class_id: String) -> void:
	var app = _app_root()
	if app == null or app.run_session == null or app.save_service == null or app.meta_service == null:
		return
	if not app.meta_service.is_class_playable(class_id):
		return
	app.reset_run()
	var run: Dictionary = app.run_session.create_new_run(class_id)
	if run.is_empty():
		return
	app.save_service.save_suspend(run, app.meta_service.meta_state)
	_show_scene("map")
