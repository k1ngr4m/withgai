extends Control

const RESOURCE_LABELS := {
	"services": "服务",
	"cache": "缓存",
	"requests": "请求",
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
	var header := UiFactory.label("精神 %d/%d  精力 %d  防线 %d  回合 %d" % [
		int(player.get("current_spirit", 0)), int(player.get("max_spirit", 0)), int(player.get("current_energy", 0)), int(player.get("current_block", 0)), int(player.get("turn_number", 1))
	], 22)
	header.name = "BattleHeader"
	main.add_child(header)
	main.add_child(_player_area(player, state))

	var enemy_row := UiFactory.hbox(10)
	enemy_row.name = "EnemyArea"
	main.add_child(enemy_row)
	var enemies: Array = state.get("enemies", [])
	for i in range(enemies.size()):
		enemy_row.add_child(_enemy_panel(enemies[i], i))
	var hand_row := UiFactory.hbox(8)
	hand_row.name = "HandArea"
	main.add_child(UiFactory.scroll(hand_row))
	var hand: Array = player.get("hand", [])
	for i in range(hand.size()):
		hand_row.add_child(_card_button(hand[i], i))
	var actions := UiFactory.hbox(8)
	actions.name = "BattleActionBar"
	main.add_child(actions)
	var end_turn := UiFactory.button("结束回合")
	end_turn.name = "EndTurnButton"
	end_turn.pressed.connect(_end_turn)
	actions.add_child(end_turn)
	var save := UiFactory.button("保存")
	save.name = "SaveBattleButton"
	save.pressed.connect(_save_battle)
	actions.add_child(save)
	var menu := UiFactory.button("主菜单")
	menu.name = "BattleMainMenuButton"
	menu.pressed.connect(_go_main_menu)
	actions.add_child(menu)
	main.add_child(_battle_log_panel(state))


func _player_area(player: Dictionary, state: Dictionary) -> Control:
	var box := UiFactory.vbox(8)
	box.name = "PlayerArea"
	box.add_child(_resource_panel(player, state))
	var player_status := _status_text(player.get("status_list", {}))
	if player_status != "无":
		box.add_child(UiFactory.label("状态 %s" % player_status, 15, Color(0.84, 0.92, 0.94)))
	return box


func _resource_panel(player: Dictionary, state: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "ResourcePanel"
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var run := AppRoot.run_session.run_state
	var cls: Dictionary = AppRoot.config_service.get_def("classes", run.get("selected_class_id", ""))
	box.add_child(UiFactory.label("%s资源面板" % String(cls.get("name", "职业")), 18, Color(0.88, 0.97, 1.0)))
	box.add_child(UiFactory.label(_resource_text(player), 15, Color(0.78, 0.92, 0.92)))
	var piles := "抽牌 %d | 手牌 %d | 弃牌 %d | 消耗 %d" % [
		int(player.get("draw_pile", []).size()),
		int(player.get("hand", []).size()),
		int(player.get("discard_pile", []).size()),
		int(player.get("exhaust_pile", []).size()),
	]
	box.add_child(UiFactory.label(piles, 14, Color(0.70, 0.84, 0.86)))
	var enemies: Array = state.get("enemies", [])
	box.add_child(UiFactory.label("敌人 %d | 当前目标 %d" % [enemies.size(), AppRoot.battle_service.selected_target_index() + 1], 14, Color(0.70, 0.84, 0.86)))
	return panel

func _enemy_panel(enemy: Dictionary, enemy_index: int) -> Control:
	var panel := UiFactory.panel()
	panel.name = "EnemyPanel%d" % enemy_index
	panel.custom_minimum_size = Vector2(260, 230)
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var def: Dictionary = AppRoot.config_service.get_def("enemies", enemy.get("enemy_def_id", ""))
	box.add_child(UiFactory.texture(def.get("art_path", ""), Vector2(210, 120)))
	var intent: Dictionary = enemy.get("intent", {})
	var selected := enemy_index == AppRoot.battle_service.selected_target_index()
	box.add_child(UiFactory.label("%s%s  HP %d/%d  防线 %d" % ["▶ " if selected else "", enemy.get("name", ""), int(enemy.get("current_hp", 0)), int(enemy.get("max_hp", 0)), int(enemy.get("current_block", 0))], 18))
	var intent_label := UiFactory.label("意图：%s %s" % [intent.get("intent_type", ""), str(intent.get("amount", ""))], 15, Color(1.0, 0.82, 0.55))
	intent_label.name = "IntentArea"
	box.add_child(intent_label)
	var preview_text := String(enemy.get("runtime_flags", {}).get("observed_next_intent_text", ""))
	if not preview_text.is_empty():
		box.add_child(UiFactory.label("预判：%s" % preview_text, 13, Color(0.62, 0.86, 1.0)))
	box.add_child(UiFactory.label("状态：%s" % _status_text(enemy.get("status_list", {})), 13, Color(0.74, 0.9, 0.92)))
	var target := UiFactory.button("设为目标")
	target.disabled = int(enemy.get("current_hp", 0)) <= 0
	target.pressed.connect(func(): _select_target(enemy_index))
	box.add_child(target)
	return panel


func _battle_log_panel(state: Dictionary) -> PanelContainer:
	var log_panel := UiFactory.panel()
	log_panel.name = "BattleLogPanel"
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_box := UiFactory.vbox(3)
	log_panel.add_child(log_box)
	var logs: Array = state.get("log", [])
	if logs.is_empty():
		log_box.add_child(UiFactory.label("战斗日志将在这里记录。", 14, Color(0.70, 0.80, 0.82)))
	else:
		for line in logs.slice(max(0, logs.size() - 8), logs.size()):
			log_box.add_child(UiFactory.label(String(line), 14, Color(0.86, 0.9, 0.9)))
	return log_panel

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
	_persist_battle_suspend()
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
	_persist_battle_suspend()

func _persist_battle_suspend() -> void:
	AppRoot.battle_service.persist_current_battle(AppRoot.run_session.run_state)
	AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)

func _go_main_menu() -> void:
	AppRoot.battle_service.persist_current_battle(AppRoot.run_session.run_state)
	AppRoot.flow_controller.show_scene("main_menu")

func _go_reward() -> void:
	_clear_resolved_battle()
	AppRoot.flow_controller.show_scene("reward")

func _go_result() -> void:
	_clear_resolved_battle()
	AppRoot.flow_controller.show_scene("run_result")

func _clear_resolved_battle() -> void:
	var phase := String(AppRoot.battle_service.battle_state.get("phase", ""))
	if ["victory", "defeat"].has(phase):
		AppRoot.battle_service.clear()

func _resource_text(player: Dictionary) -> String:
	var resources: Dictionary = player.get("class_resource_state", {})
	var parts: Array = []
	for key in resources.keys():
		parts.append("%s:%s" % [_resource_label(String(key)), resources[key]])
	return "资源 无" if parts.is_empty() else "资源 " + " ".join(parts)

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
