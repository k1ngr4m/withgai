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
	var player: Dictionary = state.get("player", {})
	add_child(_top_bar(player, state, chapter))
	add_child(_stage_layer(player, state, visual_events))
	add_child(_battle_log_panel(state))
	add_child(_bottom_hud(player))
	UiMotion.bind_buttons(self, Color(0.48, 0.86, 0.92))
	call_deferred("_play_visual_events", visual_events)


func _top_bar(player: Dictionary, state: Dictionary, chapter: int) -> Control:
	var bar := PanelContainer.new()
	bar.name = "BattleHeader"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 16
	bar.offset_top = 14
	bar.offset_right = -16
	bar.offset_bottom = 78
	bar.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.04, 0.06, 0.08, 0.82), Color(0.72, 0.86, 0.94, 0.34), 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var row := UiFactory.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	var run := AppRoot.run_session.run_state
	var class_id := String(run.get("selected_class_id", ""))
	var cls: Dictionary = AppRoot.config_service.get_def("classes", class_id)
	var title := UiFactory.label("第 %d 层  %s" % [chapter, String(cls.get("name", class_id))], 22, Color(0.95, 1.0, 0.96))
	title.custom_minimum_size = Vector2(140, 0)
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_make_single_line(title)
	row.add_child(title)

	row.add_child(_top_stat("精神", "%d/%d" % [int(player.get("current_spirit", 0)), int(player.get("max_spirit", 0))], Color(1.0, 0.46, 0.44)))
	row.add_child(_top_stat("防线", str(int(player.get("current_block", 0))), Color(0.42, 0.86, 1.0)))
	row.add_child(_top_stat("回合", str(int(player.get("turn_number", 1))), Color(1.0, 0.88, 0.45)))

	var resource_panel := _resource_panel(player, state)
	resource_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(resource_panel)

	var save := _hud_button("保存", Vector2(92, 38))
	save.name = "SaveBattleButton"
	save.pressed.connect(_save_battle)
	row.add_child(save)

	var menu := _hud_button("主菜单", Vector2(110, 38))
	menu.name = "BattleMainMenuButton"
	menu.pressed.connect(_go_main_menu)
	row.add_child(menu)
	return bar


func _top_stat(caption: String, value: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(122, 40)
	panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.01, 0.02, 0.025, 0.54), color.darkened(0.18), 6))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var label := UiFactory.label("%s %s" % [caption, value], 18, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_make_single_line(label)
	margin.add_child(label)
	return panel


func _player_area(player: Dictionary, state: Dictionary) -> Control:
	var box := UiFactory.vbox(8)
	box.name = "PlayerArea"
	box.add_child(_resource_panel(player, state))
	var player_status := _status_text(player.get("status_list", {}))
	if player_status != "无":
		box.add_child(UiFactory.label("状态 %s" % player_status, 15, Color(0.84, 0.92, 0.94)))
	return box

func _stage_layer(player: Dictionary, state: Dictionary, visual_events: Array) -> Control:
	var stage := Control.new()
	stage.name = "CombatStage"
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.offset_left = 36
	stage.offset_top = 96
	stage.offset_right = -36
	stage.offset_bottom = -290

	var player_panel := _player_actor_panel(player)
	player_panel.anchor_left = 0.08
	player_panel.anchor_top = 0.36
	player_panel.anchor_right = 0.08
	player_panel.anchor_bottom = 0.36
	player_panel.offset_left = 0
	player_panel.offset_top = 0
	player_panel.offset_right = 380
	player_panel.offset_bottom = 390
	stage.add_child(player_panel)

	var enemy_row := UiFactory.hbox(10)
	enemy_row.name = "EnemyArea"
	enemy_row.alignment = BoxContainer.ALIGNMENT_END
	enemy_row.anchor_left = 0.43
	enemy_row.anchor_top = 0.25
	enemy_row.anchor_right = 0.98
	enemy_row.anchor_bottom = 0.25
	enemy_row.offset_left = 0
	enemy_row.offset_top = 0
	enemy_row.offset_right = 0
	enemy_row.offset_bottom = 420
	var enemies: Array = state.get("enemies", [])
	for i in range(enemies.size()):
		enemy_row.add_child(_enemy_panel(enemies[i], i, visual_events))
	stage.add_child(enemy_row)
	return stage


func _combat_area(player: Dictionary, state: Dictionary, visual_events: Array) -> Control:
	return _stage_layer(player, state, visual_events)


func _bottom_hud(player: Dictionary) -> Control:
	var hud := Control.new()
	hud.name = "BattleBottomHud"
	hud.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud.offset_left = 0
	hud.offset_top = -328
	hud.offset_right = 0
	hud.offset_bottom = 0

	var hand_panel := _hand_panel(player)
	hand_panel.anchor_left = 0.20
	hand_panel.anchor_top = 0.0
	hand_panel.anchor_right = 0.82
	hand_panel.anchor_bottom = 1.0
	hand_panel.offset_left = 0
	hand_panel.offset_top = 0
	hand_panel.offset_right = 0
	hand_panel.offset_bottom = -8
	hud.add_child(hand_panel)

	var energy := _energy_orb(player)
	energy.anchor_left = 0.06
	energy.anchor_top = 0.46
	energy.anchor_right = 0.06
	energy.anchor_bottom = 0.46
	energy.offset_left = 0
	energy.offset_top = 0
	energy.offset_right = 132
	energy.offset_bottom = 132
	hud.add_child(energy)

	var end_turn := _hud_button("结束回合", Vector2(190, 58))
	end_turn.name = "EndTurnButton"
	end_turn.anchor_left = 0.84
	end_turn.anchor_top = 0.56
	end_turn.anchor_right = 0.84
	end_turn.anchor_bottom = 0.56
	end_turn.offset_left = 0
	end_turn.offset_top = 0
	end_turn.offset_right = 190
	end_turn.offset_bottom = 58
	end_turn.pressed.connect(_end_turn)
	hud.add_child(end_turn)
	return hud


func _hand_panel(player: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "HandPanel"
	panel.custom_minimum_size = Vector2(0, 318)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.03, 0.05, 0.055, 0.34), Color(0.34, 0.92, 1.0, 0.18), 8))

	var stack := Control.new()
	panel.add_child(stack)
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)

	var title := UiFactory.label("", 16, Color(0.88, 0.97, 1.0))
	title.name = "HandTitle"
	title.anchor_left = 0.0
	title.anchor_top = 0.0
	title.anchor_right = 1.0
	title.anchor_bottom = 0.0
	title.offset_left = 12
	title.offset_top = 6
	title.offset_right = -12
	title.offset_bottom = 30
	stack.add_child(title)

	var hand_scroll := Control.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.custom_minimum_size = Vector2(0, 274)
	hand_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	hand_scroll.offset_top = 24
	stack.add_child(hand_scroll)

	var hand: Array = player.get("hand", [])
	title.text = "手牌 %d 张" % hand.size()
	hand_scroll.add_child(_hand_fan(player))
	return panel


func _hand_fan(player: Dictionary) -> Control:
	var hand_area := Control.new()
	hand_area.name = "HandArea"
	hand_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	hand_area.custom_minimum_size = Vector2(0, 268)
	hand_area.clip_contents = false
	var hand: Array = player.get("hand", [])
	if hand.is_empty():
		var empty := UiFactory.label("没有可用手牌。", 15, Color(0.70, 0.80, 0.82))
		empty.anchor_left = 0.5
		empty.anchor_top = 0.48
		empty.anchor_right = 0.5
		empty.anchor_bottom = 0.48
		empty.offset_left = -90
		empty.offset_top = -12
		empty.offset_right = 90
		empty.offset_bottom = 18
		hand_area.add_child(empty)
	else:
		var viewport_width: float = get_viewport_rect().size.x
		var panel_width: float = max(720.0, viewport_width * 0.58)
		var count: int = hand.size()
		var card_size := Vector2(178, 252)
		var spacing: float = clamp(panel_width / max(1.0, float(count + 1)), 92.0, 156.0)
		var total: float = spacing * float(count - 1)
		var start_x: float = (panel_width - total - card_size.x) * 0.5
		var base_y: float = 4.0
		var mid: float = float(count - 1) * 0.5
		for i in range(hand.size()):
			var card := _card_button(hand[i], i)
			card.position = Vector2(start_x + spacing * i, base_y + abs(float(i) - mid) * 10.0)
			card.rotation_degrees = clamp((float(i) - mid) * 4.8, -18.0, 18.0)
			card.pivot_offset = card_size * 0.5
			hand_area.add_child(card)
	return hand_area


func _player_actor_panel(player: Dictionary) -> Control:
	var panel := Control.new()
	panel.name = "PlayerActorPanel"
	panel.custom_minimum_size = Vector2(340, 360)
	var run := AppRoot.run_session.run_state
	var class_id := String(run.get("selected_class_id", ""))
	var cls: Dictionary = AppRoot.config_service.get_def("classes", class_id)
	var art: Control
	var action_paths := _class_action_paths(class_id)
	if not action_paths.is_empty():
		var animator: FrameAnimator = FrameAnimatorScript.new()
		animator.name = "PlayerAnimator"
		animator.setup_actions(action_paths, _class_bust_art_path(class_id), 6, Vector2(350, 270))
		art = animator
	else:
		art = UiFactory.texture(_class_bust_art_path(class_id), Vector2(350, 270))
	if String(art.name).is_empty():
		art.name = "PlayerActorArt"
	art.anchor_left = 0.0
	art.anchor_top = 0.0
	art.anchor_right = 1.0
	art.anchor_bottom = 0.0
	art.offset_left = 0
	art.offset_top = 0
	art.offset_right = 0
	art.offset_bottom = 270
	panel.add_child(art)

	var plate := _actor_status_plate("%s  精神 %d/%d  防线 %d" % [
		String(cls.get("name", class_id)),
		int(player.get("current_spirit", 0)),
		int(player.get("max_spirit", 0)),
		int(player.get("current_block", 0)),
	], _status_text(player.get("status_list", {})), Color(0.48, 0.86, 0.92))
	plate.anchor_left = 0.06
	plate.anchor_top = 0.68
	plate.anchor_right = 0.94
	plate.anchor_bottom = 0.68
	plate.offset_left = 0
	plate.offset_top = 0
	plate.offset_right = 0
	plate.offset_bottom = 86
	panel.add_child(plate)
	return panel


func _resource_panel(player: Dictionary, state: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ResourcePanel"
	panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.01, 0.02, 0.025, 0.42), Color(0.48, 0.86, 0.92, 0.22), 6))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var box := UiFactory.vbox(2)
	margin.add_child(box)
	var run := AppRoot.run_session.run_state
	var cls: Dictionary = AppRoot.config_service.get_def("classes", run.get("selected_class_id", ""))
	box.add_child(UiFactory.label("%s资源  %s" % [String(cls.get("name", "职业")), _resource_text(player)], 14, Color(0.82, 0.96, 0.96)))
	var piles := "抽牌 %d | 手牌 %d | 弃牌 %d | 消耗 %d" % [
		int(player.get("draw_pile", []).size()),
		int(player.get("hand", []).size()),
		int(player.get("discard_pile", []).size()),
		int(player.get("exhaust_pile", []).size()),
	]
	box.add_child(UiFactory.label(piles, 13, Color(0.70, 0.84, 0.86)))
	var enemies: Array = state.get("enemies", [])
	box.add_child(UiFactory.label("敌人 %d | 当前目标 %d" % [enemies.size(), AppRoot.battle_service.selected_target_index() + 1], 12, Color(0.66, 0.80, 0.82)))
	return panel

func _enemy_panel(enemy: Dictionary, enemy_index: int, visual_events: Array) -> Control:
	var panel := Control.new()
	panel.name = "EnemyPanel%d" % enemy_index
	panel.custom_minimum_size = Vector2(330, 400)
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
	animator.anchor_left = 0.0
	animator.anchor_top = 0.12
	animator.anchor_right = 1.0
	animator.anchor_bottom = 0.12
	animator.offset_left = 0
	animator.offset_top = 0
	animator.offset_right = 0
	animator.offset_bottom = 230
	panel.add_child(animator)

	var intent: Dictionary = enemy.get("intent", {})
	var selected := enemy_index == AppRoot.battle_service.selected_target_index()
	var intent_label := UiFactory.label("意图：%s %s" % [intent.get("intent_type", ""), str(intent.get("amount", ""))], 16, Color(1.0, 0.82, 0.55))
	intent_label.name = "IntentArea"
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_label.anchor_left = 0.08
	intent_label.anchor_top = 0.0
	intent_label.anchor_right = 0.92
	intent_label.anchor_bottom = 0.0
	intent_label.offset_left = 0
	intent_label.offset_top = 0
	intent_label.offset_right = 0
	intent_label.offset_bottom = 34
	panel.add_child(intent_label)

	var plate := _actor_status_plate("%s%s  HP %d/%d  防线 %d" % ["▶ " if selected else "", enemy.get("name", ""), int(enemy.get("current_hp", 0)), int(enemy.get("max_hp", 0)), int(enemy.get("current_block", 0))], _status_text(enemy.get("status_list", {})), Color(1.0, 0.32, 0.28) if selected else Color(0.90, 0.20, 0.20))
	plate.anchor_left = 0.06
	plate.anchor_top = 0.70
	plate.anchor_right = 0.94
	plate.anchor_bottom = 0.70
	plate.offset_left = 0
	plate.offset_top = 0
	plate.offset_right = 0
	plate.offset_bottom = 84
	panel.add_child(plate)

	var preview_text := String(enemy.get("runtime_flags", {}).get("observed_next_intent_text", ""))
	if not preview_text.is_empty():
		var preview := UiFactory.label("预判：%s" % preview_text, 13, Color(0.62, 0.86, 1.0))
		preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview.anchor_left = 0.08
		preview.anchor_top = 0.09
		preview.anchor_right = 0.92
		preview.anchor_bottom = 0.09
		preview.offset_left = 0
		preview.offset_top = 0
		preview.offset_right = 0
		preview.offset_bottom = 28
		panel.add_child(preview)

	var target := _hud_button("设为目标", Vector2(132, 38))
	target.disabled = int(enemy.get("current_hp", 0)) <= 0
	target.anchor_left = 0.30
	target.anchor_top = 0.91
	target.anchor_right = 0.30
	target.anchor_bottom = 0.91
	target.offset_left = 0
	target.offset_top = 0
	target.offset_right = 132
	target.offset_bottom = 38
	target.pressed.connect(func(): _select_target(enemy_index))
	panel.add_child(target)
	return panel


func _battle_log_panel(state: Dictionary) -> PanelContainer:
	var log_panel := PanelContainer.new()
	log_panel.name = "BattleLogPanel"
	log_panel.anchor_left = 0.72
	log_panel.anchor_top = 0.12
	log_panel.anchor_right = 0.98
	log_panel.anchor_bottom = 0.12
	log_panel.offset_left = 0
	log_panel.offset_top = 0
	log_panel.offset_right = 0
	log_panel.offset_bottom = 138
	log_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.02, 0.025, 0.03, 0.48), Color(0.95, 1.0, 0.88, 0.20), 6))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	log_panel.add_child(margin)
	var log_box := UiFactory.vbox(2)
	margin.add_child(log_box)
	var logs: Array = state.get("log", [])
	if logs.is_empty():
		log_box.add_child(UiFactory.label("战斗日志将在这里记录。", 13, Color(0.70, 0.80, 0.82)))
	else:
		for line in logs.slice(max(0, logs.size() - 4), logs.size()):
			log_box.add_child(UiFactory.label(String(line), 12, Color(0.86, 0.9, 0.9)))
	return log_panel


func _energy_orb(player: Dictionary) -> PanelContainer:
	var orb := PanelContainer.new()
	orb.name = "EnergyOrb"
	orb.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.86, 0.22, 0.04, 0.92), Color(1.0, 0.86, 0.28, 0.95), 64))
	var label := UiFactory.label("%d" % int(player.get("current_energy", 0)), 38, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(label)
	return orb


func _actor_status_plate(title: String, status: String, accent: Color) -> PanelContainer:
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.02, 0.025, 0.03, 0.62), accent, 6))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	plate.add_child(margin)
	var box := UiFactory.vbox(2)
	margin.add_child(box)
	var title_label := UiFactory.label(title, 16, Color(0.96, 0.98, 0.95))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var status_label := UiFactory.label("状态：%s" % status, 12, Color(0.74, 0.9, 0.92))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status_label)
	return plate


func _hud_button(text: String, min_size := Vector2(150, 42)) -> Button:
	var button := UiFactory.button(text)
	button.custom_minimum_size = min_size
	return button


func _make_single_line(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true


func _hud_panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 8
	return style

func _card_button(card_id: String, hand_index: int) -> Button:
	var card: Dictionary = AppRoot.config_service.get_def("cards", card_id)
	var cost: String = "X" if int(card.get("cost", 0)) < 0 else str(AppRoot.battle_service.hand_card_cost(hand_index))
	var b: Button = UiFactory.card_button(card, "", Vector2(178, 252), { "cost_text": cost })
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
