extends Control

var _resolved := false
var _resolved_event_name := ""
var _resolved_option_text := ""
var _resolved_result_text := ""
var _resolved_destination := "map"


func _ready() -> void:
	if not _has_event_run():
		return
	_prepare_event()
	_build()


func _has_event_run() -> bool:
	if AppRoot.run_session == null:
		return false
	var run: Dictionary = AppRoot.run_session.run_state
	return not run.is_empty() and run.has("event_state")


func _prepare_event() -> void:
	AppRoot.reward_service.prepare_event(AppRoot.run_session.run_state)
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_battle_ch1_open_office_v1.png")
	var run := AppRoot.run_session.run_state
	var event: Dictionary = AppRoot.reward_service.current_event(run)
	var margin := UiFactory.margin(self, 36)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(_event_text_panel(event))
	if _resolved:
		main.add_child(_result_panel())
	else:
		main.add_child(_option_list_panel(event))
	main.add_child(_pause_actions())


func _event_text_panel(event: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "EventTextPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	var title := _resolved_event_name if _resolved else String(event.get("name", "随机事件"))
	var body := "事件已处理，确认后返回楼层路线。" if _resolved else String(event.get("text", ""))
	box.add_child(UiFactory.label(title, 32))
	box.add_child(UiFactory.label(body, 20, Color(0.88, 0.94, 0.95)))
	return panel


func _option_list_panel(event: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "OptionListPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("选择处理方式", 22, Color(0.86, 0.94, 0.98)))
	var options: Array = event.get("options", [])
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var b: Button = UiFactory.button(option.get("text", "选择"))
		b.name = "EventOptionButton"
		b.pressed.connect(func(): _choose(i))
		box.add_child(b)
	return panel


func _result_panel() -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "ResultPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("处理结果", 22, Color(0.86, 0.94, 0.98)))
	box.add_child(UiFactory.label("你选择了：%s" % _resolved_option_text, 16, Color(0.80, 0.92, 0.94)))
	box.add_child(UiFactory.label(_resolved_result_text, 15, Color(1.0, 0.90, 0.62)))
	var confirm := UiFactory.button("确认返回地图")
	confirm.name = "ConfirmEventResultButton"
	confirm.pressed.connect(_confirm_result)
	box.add_child(confirm)
	return panel


func _pause_actions() -> Control:
	var actions := UiFactory.hbox(8)
	actions.name = "EventActionBar"
	var save := UiFactory.button("保存")
	save.name = "SaveEventButton"
	save.pressed.connect(_save_event)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "EventMainMenuButton"
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)
	return actions

func _choose(option_index: int) -> void:
	var run := AppRoot.run_session.run_state
	var event := AppRoot.reward_service.current_event(run)
	var options: Array = event.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return
	var option: Dictionary = options[option_index]
	var before := _event_snapshot(run)
	_resolved_event_name = String(event.get("name", "随机事件"))
	_resolved_option_text = String(option.get("text", "选择"))
	_resolved_destination = AppRoot.reward_service.choose_event_option(run, option_index)
	var after := _event_snapshot(run)
	_resolved_result_text = _format_result_delta(before, after)
	_resolved = true
	AppRoot.run_session.run_state["current_scene_tag"] = "map"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
	_build()


func _confirm_result() -> void:
	var target := "run_result" if _resolved_destination == "run_victory" else "map"
	AppRoot.flow_controller.show_scene(target)

func _save_event() -> void:
	AppRoot.run_session.run_state["current_scene_tag"] = "map" if _resolved else "event"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	_save_event()
	AppRoot.flow_controller.show_scene("main_menu")


func _event_snapshot(run: Dictionary) -> Dictionary:
	return {
		"currency": int(run.get("currency_perf_points", 0)),
		"spirit": int(run.get("player_state", {}).get("current_spirit", 0)),
		"deck": int(run.get("deck_state", {}).get("master_deck", []).size()),
		"removed": int(run.get("deck_state", {}).get("removed_cards", []).size()),
		"upgraded": int(run.get("deck_state", {}).get("upgraded_cards", []).size()),
		"relics": int(run.get("owned_relic_ids", []).size()),
	}


func _format_result_delta(before: Dictionary, after: Dictionary) -> String:
	var parts: Array = []
	_add_delta(parts, "绩效点", int(before.get("currency", 0)), int(after.get("currency", 0)))
	_add_delta(parts, "精神", int(before.get("spirit", 0)), int(after.get("spirit", 0)))
	_add_delta(parts, "牌组", int(before.get("deck", 0)), int(after.get("deck", 0)))
	_add_delta(parts, "删牌记录", int(before.get("removed", 0)), int(after.get("removed", 0)))
	_add_delta(parts, "升级牌", int(before.get("upgraded", 0)), int(after.get("upgraded", 0)))
	_add_delta(parts, "遗物", int(before.get("relics", 0)), int(after.get("relics", 0)))
	return "本次选择已生效。" if parts.is_empty() else " / ".join(parts)


func _add_delta(parts: Array, label_text: String, before: int, after: int) -> void:
	var delta := after - before
	if delta == 0:
		return
	var prefix := "+" if delta > 0 else ""
	parts.append("%s %s%d" % [label_text, prefix, delta])
