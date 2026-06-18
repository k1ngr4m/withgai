extends Control

var selected_card_id: String = ""
var selected_relic_id: String = ""
var _last_reward_feedback := ""

func _ready() -> void:
	if AppRoot.run_session.run_state.get("pending_reward_state", {}).is_empty():
		AppRoot.flow_controller.show_scene("map")
		return
	selected_card_id = ""
	selected_relic_id = ""
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_reward_bg_v1.png")
	var margin := UiFactory.margin(self, 28)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	var reward: Dictionary = AppRoot.run_session.run_state.get("pending_reward_state", {})
	main.add_child(_reward_header(reward))
	main.add_child(_currency_panel(reward))
	main.add_child(_card_choice_panel(reward))
	main.add_child(_relic_choice_panel(reward))
	main.add_child(_confirm_panel())

	var actions := UiFactory.hbox(8)
	actions.name = "RewardActionBar"
	main.add_child(actions)
	var save := UiFactory.button("保存")
	save.name = "SaveRewardButton"
	save.pressed.connect(_save_reward)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "RewardMainMenuButton"
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)
	call_deferred("_animate_entry")


func _reward_header(reward: Dictionary) -> Label:
	var source := String(reward.get("source_encounter_id", ""))
	var title := "战斗奖励"
	if not source.is_empty():
		title = "战斗奖励 | %s" % source
	var label := UiFactory.label(title, 34)
	label.name = "RewardHeader"
	return label


func _currency_panel(reward: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "CurrencyPanel"
	var box := UiFactory.vbox(5)
	panel.add_child(box)
	box.add_child(UiFactory.label("绩效点 +%d" % int(reward.get("currency_amount", 0)), 22, Color(1.0, 0.9, 0.55)))
	box.add_child(UiFactory.label("领取奖励后会回到楼层路线；未选择的卡牌或遗物视为跳过。", 13, Color(0.78, 0.88, 0.90)))
	return panel


func _card_choice_panel(reward: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "CardChoicePanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("选择一张牌", 22, Color(0.86, 0.94, 0.98)))
	var row := UiFactory.hbox(10)
	row.name = "CardChoiceRow"
	box.add_child(row)
	for card_id in reward.get("candidate_card_ids", []):
		var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
		var b: Button = UiFactory.card_button(card, "", Vector2(190, 260), {
			"badge_text": "已选" if selected_card_id == String(card_id) else "",
			"selected": selected_card_id == String(card_id),
		})
		if selected_card_id == String(card_id):
			b.modulate = Color(1.0, 0.92, 0.58, 1.0)
		b.pressed.connect(func(): _select_card(String(card_id)))
		row.add_child(b)
	var skip_card := UiFactory.button("跳过卡牌")
	skip_card.name = "SkipCardButton"
	skip_card.pressed.connect(func(): _select_card(""))
	row.add_child(skip_card)
	box.add_child(UiFactory.label(_selected_card_text(), 13, Color(0.74, 0.86, 0.88)))
	return panel


func _relic_choice_panel(reward: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "RelicChoicePanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	var relics: Array = reward.get("candidate_relic_ids", [])
	box.add_child(UiFactory.label("选择一件遗物", 22, Color(0.86, 0.94, 0.98)))
	if relics.is_empty():
		box.add_child(UiFactory.label("本次没有遗物候选。", 14, Color(0.72, 0.84, 0.86)))
		return panel
	var relic_row := UiFactory.hbox(10)
	relic_row.name = "RelicChoiceRow"
	box.add_child(relic_row)
	for relic_id in relics:
		var relic: Dictionary = AppRoot.config_service.get_def("relics", relic_id)
		var relic_marker := "✓ " if selected_relic_id == String(relic_id) else ""
		var relic_button: Button = UiFactory.button("%s%s\n%s" % [relic_marker, relic.get("name", relic_id), relic.get("description", "")])
		relic_button.custom_minimum_size = Vector2(260, 130)
		if selected_relic_id == String(relic_id):
			relic_button.modulate = Color(1.0, 0.92, 0.58, 1.0)
		relic_button.pressed.connect(func(): _select_relic(String(relic_id)))
		relic_row.add_child(relic_button)
	var skip_relic := UiFactory.button("跳过遗物")
	skip_relic.name = "SkipRelicButton"
	skip_relic.pressed.connect(func(): _select_relic(""))
	relic_row.add_child(skip_relic)
	box.add_child(UiFactory.label(_selected_relic_text(), 13, Color(0.74, 0.86, 0.88)))
	return panel


func _confirm_panel() -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "RewardConfirmPanel"
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	box.add_child(UiFactory.label(_reward_selection_summary(), 14, Color(0.82, 0.94, 0.96)))
	var confirm := UiFactory.button("确认领取")
	confirm.name = "ConfirmRewardButton"
	confirm.pressed.connect(_accept_reward)
	box.add_child(confirm)
	return panel


func _selected_card_text() -> String:
	if selected_card_id.is_empty():
		return "当前卡牌选择：跳过"
	var card: Dictionary = AppRoot.config_service.get_def("cards", selected_card_id)
	return "当前卡牌选择：%s" % String(card.get("name", selected_card_id))


func _selected_relic_text() -> String:
	if selected_relic_id.is_empty():
		return "当前遗物选择：跳过"
	var relic: Dictionary = AppRoot.config_service.get_def("relics", selected_relic_id)
	return "当前遗物选择：%s" % String(relic.get("name", selected_relic_id))


func _reward_selection_summary() -> String:
	return "%s；%s" % [_selected_card_text(), _selected_relic_text()]

func _select_card(card_id: String) -> void:
	selected_card_id = card_id
	_last_reward_feedback = "card" if not card_id.is_empty() else "skip"
	_build()

func _select_relic(relic_id: String) -> void:
	selected_relic_id = relic_id
	_last_reward_feedback = "relic" if not relic_id.is_empty() else "skip"
	_build()

func _accept_reward() -> void:
	UiMotion.scan_line(self, UiMotion.REWARD, 0.22)
	await get_tree().create_timer(0.16 if not UiMotion.reduce_motion() else 0.01).timeout
	var run := AppRoot.run_session.run_state
	var result: String = AppRoot.reward_service.accept_battle_reward(run, selected_card_id, selected_relic_id)
	if result == "run_victory":
		AppRoot.flow_controller.show_scene("run_result")
	else:
		AppRoot.flow_controller.show_scene("map")

func _save_reward() -> void:
	AppRoot.run_session.run_state["current_scene_tag"] = "reward"
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	_save_reward()
	AppRoot.flow_controller.show_scene("main_menu")

func _animate_entry() -> void:
	var header := find_child("RewardHeader", true, false)
	if header != null:
		UiMotion.fade_in(header, 0.20, Vector2(0, 16))
	var currency := find_child("CurrencyPanel", true, false)
	if currency != null:
		UiMotion.pulse(currency, UiMotion.REWARD, 0.24)
	var row := find_child("CardChoiceRow", true, false)
	if row != null:
		var delay := 0.0
		for child in row.get_children():
			if child is Control:
				var captured = child
				var tween := child.create_tween()
				tween.tween_interval(delay)
				tween.tween_callback(func(): UiMotion.pop_in(captured, 0.20))
				delay += 0.05
	if _last_reward_feedback == "skip":
		var skip := find_child("SkipCardButton", true, false)
		if skip != null:
			UiMotion.flash_modulate(skip, Color(0.55, 0.65, 0.72), 0.14)
	elif not _last_reward_feedback.is_empty():
		UiMotion.scan_line(self, UiMotion.REWARD, 0.16)
	_last_reward_feedback = ""
