extends Control

func _ready() -> void:
	if not _has_rest_run():
		return
	_build_main()


func _has_rest_run() -> bool:
	if AppRoot.run_session == null:
		return false
	var run: Dictionary = AppRoot.run_session.run_state
	return not run.is_empty() and run.has("player_state") and run.has("deck_state")


func _build_main() -> void:
	_clear_children()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_rest_break_room_v1.png")
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 36)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(_rest_header("休息处"))
	main.add_child(_rest_status_panel(run))
	main.add_child(_rest_choice_panel(run))
	main.add_child(_pause_actions())
	call_deferred("_animate_entry")


func _rest_header(text: String) -> Label:
	var label := UiFactory.label(text, 34)
	label.name = "RestHeader"
	return label


func _rest_status_panel(run: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "RestStatusPanel"
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var player_state: Dictionary = run.get("player_state", {})
	box.add_child(UiFactory.label("精神 %d/%d" % [
		int(player_state.get("current_spirit", 0)),
		int(player_state.get("max_spirit", 0)),
	], 22, Color(0.86, 0.94, 0.98)))
	box.add_child(UiFactory.label("预计冥想恢复：%d" % _rest_recover_preview(run), 15, Color(0.82, 0.92, 0.94)))
	box.add_child(UiFactory.label("可复盘升级：%d 张 | 牌组 %d 张" % [
		_eligible_upgrade_count(run),
		int(run.get("deck_state", {}).get("master_deck", []).size()),
	], 15, Color(0.72, 0.84, 0.86)))
	return panel


func _rest_choice_panel(run: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "RestChoicePanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("选择休息方式", 22, Color(0.86, 0.94, 0.98)))
	var recover := UiFactory.button("冥想：恢复精神状态")
	recover.name = "RecoverButton"
	recover.pressed.connect(_recover)
	box.add_child(recover)
	var upgrade := UiFactory.button("复盘：升级一张牌")
	upgrade.name = "UpgradeButton"
	upgrade.disabled = _eligible_upgrade_count(run) <= 0
	upgrade.pressed.connect(_show_upgrade_choices)
	box.add_child(upgrade)
	return panel

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _recover() -> void:
	AppRoot.reward_service.rest_recover(AppRoot.run_session.run_state)
	UiMotion.scan_line(self, UiMotion.BLOCK, 0.20)
	await get_tree().create_timer(0.16 if not UiMotion.reduce_motion() else 0.01).timeout
	AppRoot.flow_controller.show_scene("map")

func _show_upgrade_choices() -> void:
	_clear_children()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/bg_rest_break_room_v1.png")
	var run := AppRoot.run_session.run_state
	var margin := UiFactory.margin(self, 36)
	var main := UiFactory.vbox(10)
	margin.add_child(main)
	main.add_child(_rest_header("选择要复盘升级的牌"))
	var panel := UiFactory.panel()
	panel.name = "UpgradeChoicePanel"
	main.add_child(panel)
	var panel_box := UiFactory.vbox(8)
	panel.add_child(panel_box)
	var choices := UiFactory.vbox(6)
	choices.name = "UpgradeChoiceList"
	panel_box.add_child(UiFactory.scroll(choices))
	var deck_state: Dictionary = run.get("deck_state", {})
	var master_deck: Array = deck_state.get("master_deck", [])
	var upgraded_cards: Array = deck_state.get("upgraded_cards", [])
	var seen: Array = []
	var eligible_count := 0
	for card_id in master_deck:
		if seen.has(card_id):
			continue
		seen.append(card_id)
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var upgraded: bool = upgraded_cards.has(card_id)
		if not upgraded:
			eligible_count += 1
		var b := UiFactory.button("%s%s\n%s" % [card.get("name", card_id), " +" if upgraded else "", card.get("description", "")])
		b.name = "UpgradeCardButton"
		b.disabled = upgraded
		b.pressed.connect(func(): _upgrade(card_id))
		choices.add_child(b)
	if eligible_count == 0:
		choices.add_child(UiFactory.label("当前牌组已经全部复盘过。", 18, Color(0.88, 0.94, 0.95)))
	var back := UiFactory.button("返回")
	back.name = "BackToRestButton"
	back.pressed.connect(_build_main)
	main.add_child(back)
	main.add_child(_pause_actions())
	call_deferred("_animate_entry")

func _upgrade(card_id: String) -> void:
	AppRoot.reward_service.rest_upgrade_card(AppRoot.run_session.run_state, card_id)
	UiMotion.scan_line(self, UiMotion.REWARD, 0.20)
	await get_tree().create_timer(0.16 if not UiMotion.reduce_motion() else 0.01).timeout
	AppRoot.flow_controller.show_scene("map")

func _pause_actions() -> Control:
	var actions := UiFactory.hbox(8)
	actions.name = "RestActionBar"
	var save := UiFactory.button("保存")
	save.name = "SaveRestButton"
	save.pressed.connect(_save_rest)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "RestMainMenuButton"
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)
	return actions

func _save_rest() -> void:
	AppRoot.run_session.run_state["current_scene_tag"] = "rest"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	_save_rest()
	AppRoot.flow_controller.show_scene("main_menu")


func _rest_recover_preview(run: Dictionary) -> int:
	var player_state: Dictionary = run.get("player_state", {})
	var max_spirit := int(player_state.get("max_spirit", 72))
	return int(float(max_spirit) * 0.3) + AppRoot.meta_service.get_upgrade_level("meta_nap_bed") * 4


func _eligible_upgrade_count(run: Dictionary) -> int:
	var deck_state: Dictionary = run.get("deck_state", {})
	var master_deck: Array = deck_state.get("master_deck", [])
	var upgraded_cards: Array = deck_state.get("upgraded_cards", [])
	var seen: Array = []
	var count := 0
	for card_id in master_deck:
		if seen.has(card_id):
			continue
		seen.append(card_id)
		if not upgraded_cards.has(card_id):
			count += 1
	return count

func _animate_entry() -> void:
	var header := find_child("RestHeader", true, false)
	if header != null:
		UiMotion.fade_in(header, 0.24, Vector2(0, 16))
	var status := find_child("RestStatusPanel", true, false)
	if status != null:
		UiMotion.fade_in(status, 0.24, Vector2(0, 16))
	var choices := find_child("RestChoicePanel", true, false)
	if choices != null:
		UiMotion.fade_in(choices, 0.24, Vector2(0, 16))
	var upgrade_list := find_child("UpgradeChoiceList", true, false)
	if upgrade_list != null:
		UiMotion.fade_in_children(upgrade_list, 0.14, Vector2(0, 10), 0.025)
