extends Control

const FrameAnimatorScript := preload("res://Scripts/UI/FrameAnimator.gd")

const CLASS_SPRITE_BUNDLES := {
	"backend": "res://Resources/Art/Generated/P1/sprites/char_backend_sprite_bundle_v1",
	"frontend": "res://Resources/Art/Generated/P1/sprites/char_frontend_sprite_bundle_v1",
	"tester": "res://Resources/Art/Generated/P1/sprites/char_tester_sprite_bundle_v1",
	"algorithm": "res://Resources/Art/Generated/P1/sprites/char_algorithm_sprite_bundle_v1",
	"product_manager": "res://Resources/Art/Generated/P1/sprites/char_product_manager_sprite_bundle_v1",
	"hr": "res://Resources/Art/Generated/P2/sprites/char_hr_sprite_bundle_v1",
}
const CLASS_CAST_ACTION := {
	"backend": "skill_cast",
	"frontend": "skill_cast",
	"tester": "debuff_cast",
	"algorithm": "cast",
	"product_manager": "command_cast",
	"hr": "execute_cast",
}
const CLASS_BUST_ART := {
	"backend": "res://Resources/Art/Generated/P0/characters/char_backend_bust_v1/final.png",
	"frontend": "res://Resources/Art/Generated/P0/characters/char_frontend_bust_v1/final.png",
	"tester": "res://Resources/Art/Generated/P0/characters/char_tester_bust_v1/final.png",
	"algorithm": "res://Resources/Art/Generated/P0/characters/char_algorithm_bust_v1/final.png",
	"product_manager": "res://Resources/Art/Generated/P0/characters/char_product_manager_bust_v1/final.png",
	"hr": "res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png",
}

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

var _queued_ui_events: Array = []
var _transition_after_motion := ""

func _ready() -> void:
	if AppRoot.battle_service.battle_state.is_empty() and not AppRoot.battle_service.restore_battle(AppRoot.run_session.run_state):
		AppRoot.flow_controller.show_scene("map")
		return
	_build()

func _build() -> void:
	var state := AppRoot.battle_service.battle_state
	var visual_events := _consume_visual_events(state)
	visual_events.append_array(_queued_ui_events)
	_queued_ui_events = []
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
	var player: Dictionary = state.get("player", {})
	var header := UiFactory.label("精神 %d/%d  精力 %d  防线 %d  回合 %d" % [
		int(player.get("current_spirit", 0)), int(player.get("max_spirit", 0)), int(player.get("current_energy", 0)), int(player.get("current_block", 0)), int(player.get("turn_number", 1))
	], 22)
	header.name = "BattleHeader"
	main.add_child(header)
	main.add_child(_player_area(player, state))
	main.add_child(_combat_area(player, state, visual_events))
	main.add_child(_hand_panel(player))
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
	UiMotion.bind_buttons(self, Color(0.48, 0.86, 0.92))
	call_deferred("_play_visual_events", visual_events)


func _player_area(player: Dictionary, state: Dictionary) -> Control:
	var box := UiFactory.vbox(8)
	box.name = "PlayerArea"
	box.add_child(_resource_panel(player, state))
	var player_status := _status_text(player.get("status_list", {}))
	if player_status != "无":
		box.add_child(UiFactory.label("状态 %s" % player_status, 15, Color(0.84, 0.92, 0.94)))
	return box

func _combat_area(player: Dictionary, state: Dictionary, visual_events: Array) -> Control:
	var row := UiFactory.hbox(12)
	row.name = "CombatStage"
	row.custom_minimum_size = Vector2(0, 370)
	row.add_child(_player_actor_panel(player))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var enemy_row := UiFactory.hbox(10)
	enemy_row.name = "EnemyArea"
	enemy_row.alignment = BoxContainer.ALIGNMENT_END
	enemy_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	var enemies: Array = state.get("enemies", [])
	for i in range(enemies.size()):
		enemy_row.add_child(_enemy_panel(enemies[i], i, visual_events))
	row.add_child(enemy_row)
	return row


func _hand_panel(player: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "HandPanel"
	panel.custom_minimum_size = Vector2(0, 206)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var hand: Array = player.get("hand", [])
	box.add_child(UiFactory.label("手牌 %d 张" % hand.size(), 16, Color(0.88, 0.97, 1.0)))
	var hand_row := UiFactory.hbox(8)
	hand_row.name = "HandArea"
	hand_row.custom_minimum_size = Vector2(0, 156)
	hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hand_scroll := UiFactory.scroll(hand_row)
	hand_scroll.name = "HandScroll"
	hand_scroll.custom_minimum_size = Vector2(0, 162)
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(hand_scroll)
	if hand.is_empty():
		hand_row.add_child(UiFactory.label("没有可用手牌。", 14, Color(0.70, 0.80, 0.82)))
	else:
		for i in range(hand.size()):
			hand_row.add_child(_card_button(hand[i], i))
	return panel


func _player_actor_panel(player: Dictionary) -> Control:
	var panel := UiFactory.panel()
	panel.name = "PlayerActorPanel"
	panel.custom_minimum_size = Vector2(340, 360)
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var run := AppRoot.run_session.run_state
	var class_id := String(run.get("selected_class_id", ""))
	var cls: Dictionary = AppRoot.config_service.get_def("classes", class_id)
	var art: Control
	var action_paths := _class_action_paths(class_id)
	if not action_paths.is_empty():
		var animator: FrameAnimator = FrameAnimatorScript.new()
		animator.name = "PlayerAnimator"
		animator.setup_actions(action_paths, _class_bust_art_path(class_id), 6, Vector2(320, 245))
		art = animator
	else:
		art = UiFactory.texture(_class_bust_art_path(class_id), Vector2(320, 245))
	if String(art.name).is_empty():
		art.name = "PlayerActorArt"
	box.add_child(art)
	box.add_child(UiFactory.label("%s  精神 %d/%d  防线 %d" % [
		cls.get("name", class_id),
		int(player.get("current_spirit", 0)),
		int(player.get("max_spirit", 0)),
		int(player.get("current_block", 0)),
	], 18))
	box.add_child(UiFactory.label("状态：%s" % _status_text(player.get("status_list", {})), 13, Color(0.74, 0.9, 0.92)))
	return panel


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

func _enemy_panel(enemy: Dictionary, enemy_index: int, visual_events: Array) -> Control:
	var panel := UiFactory.panel()
	panel.name = "EnemyPanel%d" % enemy_index
	panel.custom_minimum_size = Vector2(360, 360)
	var box := UiFactory.vbox(6)
	panel.add_child(box)
	var def: Dictionary = AppRoot.config_service.get_def("enemies", enemy.get("enemy_def_id", ""))
	var animator: FrameAnimator = FrameAnimatorScript.new()
	animator.name = "EnemyAnimator%d" % enemy_index
	animator.setup_actions({
		"idle": def.get("idle_frame_paths", []),
		"attack": def.get("attack_frame_paths", []),
		"hurt": def.get("hurt_frame_paths", []),
		"death": def.get("hurt_frame_paths", []),
		"boss_phase": def.get("attack_frame_paths", []),
	}, String(def.get("art_path", "")), int(def.get("animation_fps", 6)), Vector2(320, 210))
	var event_action := _visual_event_action_for(enemy_index, visual_events)
	if event_action == "attack":
		animator.play_action("attack")
	elif event_action == "hurt":
		animator.play_action("hurt")
	box.add_child(animator)
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
	b.name = "CardButton%d" % hand_index
	b.disabled = not AppRoot.battle_service.can_play_card(hand_index)
	if b.disabled:
		b.modulate = Color(0.72, 0.72, 0.72, 0.88)
	b.pressed.connect(func(): _play_card(hand_index, b))
	return b

func _play_card(hand_index: int, button: Button = null) -> void:
	if button != null and is_instance_valid(button):
		UiMotion.press(button)
	var before := _battle_snapshot()
	AppRoot.battle_service.play_card(AppRoot.run_session.run_state, hand_index, AppRoot.battle_service.selected_target_index())
	_queue_snapshot_events(before, _battle_snapshot())
	_after_action()

func _select_target(enemy_index: int) -> void:
	var before := _battle_snapshot()
	AppRoot.battle_service.select_target(enemy_index)
	_persist_battle_suspend()
	_queue_snapshot_events(before, _battle_snapshot())
	_build()

func _end_turn() -> void:
	var before := _battle_snapshot()
	AppRoot.battle_service.end_turn(AppRoot.run_session.run_state)
	_queue_snapshot_events(before, _battle_snapshot())
	_after_action()

func _after_action() -> void:
	var phase: String = String(AppRoot.battle_service.battle_state.get("phase", ""))
	if phase == "victory":
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_transition_after_motion = "reward"
		_build()
		call_deferred("_deferred_transition")
	elif phase == "defeat":
		AppRoot.run_session.run_state["run_flags"]["victory"] = false
		_transition_after_motion = "run_result"
		_build()
		call_deferred("_deferred_transition")
	else:
		AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
		_build()

func _deferred_transition() -> void:
	if _transition_after_motion.is_empty():
		return
	await get_tree().create_timer(0.45 if not UiMotion.reduce_motion() else 0.05).timeout
	var target := _transition_after_motion
	_transition_after_motion = ""
	if target == "reward":
		_go_reward()
	elif target == "run_result":
		_go_result()

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

func _class_bust_art_path(class_id: String) -> String:
	return String(CLASS_BUST_ART.get(class_id, ""))

func _class_action_paths(class_id: String) -> Dictionary:
	var base := String(CLASS_SPRITE_BUNDLES.get(class_id, ""))
	if base.is_empty():
		return {}
	var paths := {}
	for action in ["idle", "run", "hurt", "attack", "skill_cast", "cast", "charge", "debuff_cast", "command_cast", "execute_cast"]:
		var frames := _processed_action_frames(base, action)
		if not frames.is_empty():
			paths[action] = frames
	return paths

func _processed_action_frames(base: String, action: String) -> Array:
	var frames: Array = []
	var prefix := action
	if action.ends_with("cast") or action == "command_cast" or action == "debuff_cast" or action == "execute_cast":
		prefix = "cast"
	var processed := "%s/%s/processed" % [base, action]
	for i in range(1, 9):
		var path := "%s/%s-%d.png" % [processed, prefix, i]
		if ResourceLoader.exists(path):
			frames.append(path)
	return frames

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

func _battle_snapshot() -> Dictionary:
	var state := AppRoot.battle_service.battle_state
	var player: Dictionary = state.get("player", {})
	var enemy_snapshots: Array = []
	for enemy in state.get("enemies", []):
		var intent: Dictionary = enemy.get("intent", {})
		enemy_snapshots.append({
			"hp": int(enemy.get("current_hp", 0)),
			"block": int(enemy.get("current_block", 0)),
			"intent_type": String(intent.get("intent_type", "")),
			"intent_amount": int(intent.get("amount", 0)),
		})
	return {
		"phase": String(state.get("phase", "")),
		"log_size": int(state.get("log", []).size()),
		"spirit": int(player.get("current_spirit", 0)),
		"block": int(player.get("current_block", 0)),
		"energy": int(player.get("current_energy", 0)),
		"resources": player.get("class_resource_state", {}).duplicate(true),
		"selected_target_index": int(state.get("selected_target_index", 0)),
		"enemies": enemy_snapshots,
	}

func _queue_snapshot_events(before: Dictionary, after: Dictionary) -> void:
	var service_events: Array = AppRoot.battle_service.battle_state.get("visual_events", [])
	var events := _events_from_snapshot(before, after, service_events)
	_queued_ui_events.append_array(events)

func _events_from_snapshot(before: Dictionary, after: Dictionary, service_events: Array) -> Array:
	if before.is_empty() or after.is_empty():
		return []
	var events: Array = []
	var spirit_delta := int(after.get("spirit", 0)) - int(before.get("spirit", 0))
	if spirit_delta < 0 and not _has_visual_type(service_events, "player_damage"):
		events.append({ "type": "player_damage", "target": "player", "amount": -spirit_delta, "label": "%d 精神" % spirit_delta })
	var block_delta := int(after.get("block", 0)) - int(before.get("block", 0))
	if block_delta > 0 and not _has_visual_type(service_events, "block"):
		events.append({ "type": "block", "target": "player", "amount": block_delta, "label": "+%d 防线" % block_delta })
	var energy_delta := int(after.get("energy", 0)) - int(before.get("energy", 0))
	if energy_delta != 0:
		events.append({ "type": "energy", "target": "player", "amount": energy_delta, "label": "%+d 精力" % energy_delta })
	var before_resources: Dictionary = before.get("resources", {})
	var after_resources: Dictionary = after.get("resources", {})
	for key in after_resources.keys():
		var delta := int(after_resources.get(key, 0)) - int(before_resources.get(key, 0))
		if delta != 0 and not _has_resource_event(service_events, String(key)):
			events.append({ "type": "resource", "target": "player", "resource_id": String(key), "amount": delta, "label": "%+d %s" % [delta, _resource_label(String(key))] })
	var before_enemies: Array = before.get("enemies", [])
	var after_enemies: Array = after.get("enemies", [])
	for i in range(min(before_enemies.size(), after_enemies.size())):
		var b: Dictionary = before_enemies[i]
		var a: Dictionary = after_enemies[i]
		var hp_delta := int(a.get("hp", 0)) - int(b.get("hp", 0))
		if hp_delta < 0 and not _has_enemy_event(service_events, "damage", i):
			events.append({ "type": "damage", "target": "enemy", "enemy_index": i, "amount": -hp_delta, "label": "%d" % hp_delta })
		var intent_delta := int(a.get("intent_amount", 0)) - int(b.get("intent_amount", 0))
		if intent_delta != 0 and not _has_enemy_event(service_events, "intent", i):
			events.append({ "type": "intent", "target": "enemy", "enemy_index": i, "amount": intent_delta, "label": "意图 %+d" % intent_delta })
	return events

func _has_visual_type(events: Array, type_name: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == type_name:
			return true
	return false

func _has_resource_event(events: Array, resource_id: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == "resource" and String(event.get("resource_id", "")) == resource_id:
			return true
	return false

func _has_enemy_event(events: Array, type_name: String, enemy_index: int) -> bool:
	for event in events:
		if String(event.get("type", "")) == type_name and int(event.get("enemy_index", -1)) == enemy_index:
			return true
	return false

func _play_visual_events(events: Array) -> void:
	var hand_area := find_child("HandArea", true, false) as Control
	if hand_area != null:
		UiMotion.fade_in_children(hand_area, 0.16, Vector2(0, 12), 0.025)
	if events.is_empty():
		return
	var player_panel := find_child("PlayerActorPanel", true, false) as Control
	var resource_panel := find_child("ResourcePanel", true, false) as Control
	var header := find_child("BattleHeader", true, false) as Control
	var log_panel := find_child("BattleLogPanel", true, false) as Control
	var player_animator := find_child("PlayerAnimator", true, false)
	for event in events:
		var type_name := String(event.get("type", ""))
		match type_name:
			"card_played":
				if hand_area != null:
					UiMotion.scan_line(hand_area, _card_type_color(String(event.get("card_type", ""))))
				if player_animator != null and player_animator is FrameAnimator:
					(player_animator as FrameAnimator).play_action(_player_action_for_card_type(String(event.get("card_type", ""))))
			"damage":
				var enemy_panel := _enemy_panel_node(int(event.get("enemy_index", -1)))
				if enemy_panel != null:
					UiMotion.flash_modulate(enemy_panel, UiMotion.DAMAGE, 0.18)
					UiMotion.shake(enemy_panel, 8.0, 0.16)
					UiMotion.float_text(enemy_panel, String(event.get("label", "-%d" % int(event.get("amount", 0)))), UiMotion.DAMAGE, Vector2(28, 44))
			"player_damage":
				if player_panel != null:
					UiMotion.flash_modulate(player_panel, UiMotion.DAMAGE, 0.18)
					UiMotion.shake(player_panel, 6.0, 0.15)
					UiMotion.float_text(player_panel, String(event.get("label", "-%d 精神" % int(event.get("amount", 0)))), UiMotion.DAMAGE, Vector2(28, 44))
			"block":
				if resource_panel != null:
					UiMotion.pulse(resource_panel, UiMotion.BLOCK, 0.20)
					UiMotion.float_text(resource_panel, String(event.get("label", "")), UiMotion.BLOCK, Vector2(24, 32))
			"resource":
				if resource_panel != null:
					var color := _resource_color(String(event.get("resource_id", "")))
					UiMotion.pulse(resource_panel, color, 0.20)
					UiMotion.float_text(resource_panel, String(event.get("label", "")), color, Vector2(24, 54))
			"energy":
				if header != null:
					UiMotion.pulse(header, UiMotion.REQUEST, 0.14)
			"intent":
				var target_panel := _enemy_panel_node(int(event.get("enemy_index", -1)))
				if target_panel != null:
					UiMotion.flash_modulate(target_panel, UiMotion.REQUEST, 0.18)
					UiMotion.float_text(target_panel, String(event.get("label", "")), UiMotion.REQUEST, Vector2(30, 76))
			"target":
				var selected_panel := _enemy_panel_node(int(event.get("enemy_index", -1)))
				if selected_panel != null:
					UiMotion.flash_modulate(selected_panel, UiMotion.SERVICE, 0.18)
			"turn_end":
				if player_panel != null:
					UiMotion.flash_modulate(player_panel, Color(0.48, 0.54, 0.58), 0.20)
			"boss_phase":
				var phase_panel := _enemy_panel_node(int(event.get("enemy_index", -1)))
				if phase_panel != null:
					UiMotion.flash_modulate(phase_panel, UiMotion.REQUEST, 0.28)
					UiMotion.float_text(phase_panel, String(event.get("label", "阶段切换")), UiMotion.REQUEST, Vector2(28, 38))
			_:
				if event.has("action"):
					var action_panel := _enemy_panel_node(int(event.get("enemy_index", -1)))
					if action_panel != null:
						UiMotion.flash_modulate(action_panel, UiMotion.DAMAGE if String(event.get("action", "")) == "hurt" else UiMotion.REQUEST, 0.12)
	if log_panel != null:
		UiMotion.pulse(log_panel, Color(0.95, 1.0, 0.88), 0.14)
	if _transition_after_motion == "reward":
		UiMotion.scan_line(self, UiMotion.REWARD, 0.32)
	elif _transition_after_motion == "run_result":
		UiMotion.flash_modulate(self, Color(0.45, 0.08, 0.09), 0.30)

func _enemy_panel_node(enemy_index: int) -> Control:
	if enemy_index < 0:
		return null
	return find_child("EnemyPanel%d" % enemy_index, true, false) as Control

func _player_action_for_card_type(card_type: String) -> String:
	var class_id := String(AppRoot.run_session.run_state.get("selected_class_id", ""))
	match card_type:
		"attack":
			return "attack"
		"power", "skill":
			return String(CLASS_CAST_ACTION.get(class_id, "cast"))
		_:
			return String(CLASS_CAST_ACTION.get(class_id, "cast"))

func _card_type_color(card_type: String) -> Color:
	match card_type:
		"attack":
			return UiMotion.DAMAGE
		"power":
			return UiMotion.SERVICE
		"skill":
			return UiMotion.BLOCK
		_:
			return UiMotion.WHITE_SCAN

func _resource_color(resource_id: String) -> Color:
	match resource_id:
		"services":
			return UiMotion.SERVICE
		"cache":
			return UiMotion.CACHE
		"requests":
			return UiMotion.REQUEST
		"performance":
			return UiMotion.REWARD
		_:
			return UiMotion.BLOCK

func _consume_visual_events(state: Dictionary) -> Array:
	var events: Array = state.get("visual_events", []).duplicate(true)
	state["visual_events"] = []
	return events

func _visual_event_action_for(enemy_index: int, visual_events: Array) -> String:
	var action := ""
	for event in visual_events:
		if int(event.get("enemy_index", -1)) == enemy_index:
			action = String(event.get("action", action))
	return action
