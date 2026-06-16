extends Control

const RESOURCE_LABELS := {
	"services": "服务",
	"cache": "缓存",
	"components": "组件",
	"style_layers": "样式层",
	"bugs": "Bug",
	"cases": "用例",
	"diff_tags": "Diff",
	"compute": "算力",
	"complexity": "复杂度",
	"priority_targets": "优先级",
	"requirement_change_marks": "需求变更",
	"performance": "绩效",
	"optimization_targets": "优化名单",
}

func _ready() -> void:
	if AppRoot.battle_service.battle_state.is_empty() and not AppRoot.battle_service.restore_battle(AppRoot.run_session.run_state):
		AppRoot.flow_controller.show_scene("map")
		return
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	var chapter: int = int(AppRoot.run_session.run_state.get("current_chapter", 1))
	var bg := "res://Resources/Art/Generated/P0/backgrounds/bg_battle_ch1_open_office_v1.png"
	if chapter == 2:
		bg = "res://Resources/Art/Generated/P0/backgrounds/bg_battle_ch2_management_zone_v1.png"
	elif chapter == 3:
		bg = "res://Resources/Art/Generated/P0/backgrounds/bg_battle_ch3_ceo_floor_v1.png"
	UiFactory.add_background(self, bg)
	var margin := UiFactory.margin(self, 16)
	var main := UiFactory.vbox(8)
	margin.add_child(main)
	var state := AppRoot.battle_service.battle_state
	var player: Dictionary = state.get("player", {})
	main.add_child(UiFactory.label("精神 %d/%d  精力 %d  防线 %d  回合 %d  %s" % [
		int(player.get("current_spirit", 0)), int(player.get("max_spirit", 0)), int(player.get("current_energy", 0)), int(player.get("current_block", 0)), int(player.get("turn_number", 1)), _resource_text(player)
	], 22))
	var player_status := _status_text(player.get("status_list", {}))
	if player_status != "无":
		main.add_child(UiFactory.label("状态 %s" % player_status, 15, Color(0.84, 0.92, 0.94)))
	var enemy_row := UiFactory.hbox(10)
	main.add_child(enemy_row)
	var enemies: Array = state.get("enemies", [])
	for i in range(enemies.size()):
		enemy_row.add_child(_enemy_panel(enemies[i], i))
	var hand_row := UiFactory.hbox(8)
	main.add_child(UiFactory.scroll(hand_row))
	var hand: Array = player.get("hand", [])
	for i in range(hand.size()):
		hand_row.add_child(_card_button(hand[i], i))
	var actions := UiFactory.hbox(8)
	main.add_child(actions)
	var end_turn := UiFactory.button("结束回合")
	end_turn.pressed.connect(_end_turn)
	actions.add_child(end_turn)
	var save := UiFactory.button("保存")
	save.pressed.connect(_save_battle)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	actions.add_child(menu)
	var log_panel := UiFactory.panel()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_box := UiFactory.vbox(3)
	log_panel.add_child(log_box)
	var logs: Array = state.get("log", [])
	for line in logs.slice(max(0, logs.size() - 8), logs.size()):
		log_box.add_child(UiFactory.label(String(line), 14, Color(0.86, 0.9, 0.9)))
	main.add_child(log_panel)

func _enemy_panel(enemy: Dictionary, enemy_index: int) -> Control:
	var panel := UiFactory.panel()
	panel.custom_minimum_size = Vector2(260, 230)
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var def: Dictionary = AppRoot.config_service.get_def("enemies", enemy.get("enemy_def_id", ""))
	box.add_child(UiFactory.texture(def.get("art_path", ""), Vector2(210, 120)))
	var intent: Dictionary = enemy.get("intent", {})
	var selected := enemy_index == AppRoot.battle_service.selected_target_index()
	box.add_child(UiFactory.label("%s%s  HP %d/%d  防线 %d" % ["▶ " if selected else "", enemy.get("name", ""), int(enemy.get("current_hp", 0)), int(enemy.get("max_hp", 0)), int(enemy.get("current_block", 0))], 18))
	box.add_child(UiFactory.label("意图：%s %s" % [intent.get("intent_type", ""), str(intent.get("amount", ""))], 15, Color(1.0, 0.82, 0.55)))
	box.add_child(UiFactory.label("状态：%s" % _status_text(enemy.get("status_list", {})), 13, Color(0.74, 0.9, 0.92)))
	var target := UiFactory.button("设为目标")
	target.disabled = int(enemy.get("current_hp", 0)) <= 0
	target.pressed.connect(func(): _select_target(enemy_index))
	box.add_child(target)
	return panel

func _card_button(card_id: String, hand_index: int) -> Button:
	var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
	var cost: String = "X" if int(card.get("cost", 0)) < 0 else str(AppRoot.battle_service.hand_card_cost(hand_index))
	var b: Button = UiFactory.card_button(card, "%s [%s]\n%s\n%s" % [card.get("name", card_id), cost, card.get("type", ""), card.get("description", "")], Vector2(190, 150))
	b.disabled = not AppRoot.battle_service.can_play_card(hand_index)
	b.pressed.connect(func(): _play_card(hand_index))
	return b

func _play_card(hand_index: int) -> void:
	AppRoot.battle_service.play_card(AppRoot.run_session.run_state, hand_index, AppRoot.battle_service.selected_target_index())
	_after_action()

func _select_target(enemy_index: int) -> void:
	AppRoot.battle_service.select_target(enemy_index)
	_build()

func _end_turn() -> void:
	AppRoot.battle_service.end_turn(AppRoot.run_session.run_state)
	_after_action()

func _after_action() -> void:
	var phase: String = String(AppRoot.battle_service.battle_state.get("phase", ""))
	if phase == "victory":
		call_deferred("_go_reward")
	elif phase == "defeat":
		AppRoot.run_session.run_state["run_flags"]["victory"] = false
		call_deferred("_go_result")
	else:
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_build()

func _save_battle() -> void:
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_reward() -> void:
	AppRoot.flow_controller.show_scene("reward")

func _go_result() -> void:
	AppRoot.flow_controller.show_scene("run_result")

func _resource_text(player: Dictionary) -> String:
	var resources: Dictionary = player.get("class_resource_state", {})
	var parts: Array = []
	for key in resources.keys():
		parts.append("%s:%s" % [_resource_label(String(key)), resources[key]])
	return "资源 " + " ".join(parts)

func _resource_label(resource_id: String) -> String:
	return String(RESOURCE_LABELS.get(resource_id, resource_id))

func _status_text(statuses: Dictionary) -> String:
	var parts: Array = []
	for status_id in statuses.keys():
		var amount := int(statuses.get(status_id, 0))
		if amount <= 0:
			continue
		var def: Dictionary = AppRoot.config_service.get_def("statuses", String(status_id))
		if bool(def.get("is_hidden", false)):
			continue
		parts.append("%s:%d" % [def.get("name", status_id), amount])
	return "无" if parts.is_empty() else " ".join(parts)
