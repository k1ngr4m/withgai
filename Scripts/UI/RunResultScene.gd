extends Control

func _ready() -> void:
	if not _has_result_run():
		return
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_reward_bg_v1.png")
	var run := AppRoot.run_session.run_state
	var victory: bool = bool(run.get("run_flags", {}).get("victory", false))
	AppRoot.meta_service.settle_run(run, victory)
	var settlement: Dictionary = run.get("settlement_state", {})
	AppRoot.save_service.clear_suspend()
	var margin := UiFactory.margin(self, 40)
	var main := UiFactory.vbox(14)
	margin.add_child(main)
	main.add_child(_result_header(victory))
	main.add_child(_result_summary_panel(run, settlement))
	main.add_child(_meta_reward_panel(settlement))
	main.add_child(_result_actions_panel())


func _has_result_run() -> bool:
	if AppRoot.run_session == null:
		return false
	var run: Dictionary = AppRoot.run_session.run_state
	return not run.is_empty()


func _result_header(victory: bool) -> Label:
	var label := UiFactory.label("晋升成功" if victory else "本局结束", 42)
	label.name = "RunResultHeader"
	return label


func _result_summary_panel(run: Dictionary, settlement: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "ResultSummaryPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("单局复盘", 24, Color(0.90, 0.98, 1.0)))
	box.add_child(UiFactory.label("最高楼层 %d  击败 Boss %d" % [
		int(settlement.get("highest_floor", run.get("current_floor", 1))),
		int(settlement.get("boss_count", run.get("defeated_boss_ids", []).size())),
	], 22))
	box.add_child(UiFactory.label("战斗 %d  精英 %d  事件 %d  商店 %d  休息 %d  处理敌人 %d" % [
		int(settlement.get("battle_count", 0)),
		int(settlement.get("elite_count", 0)),
		int(settlement.get("event_count", 0)),
		int(settlement.get("shop_count", 0)),
		int(settlement.get("rest_count", 0)),
		int(settlement.get("enemy_count", 0)),
	], 18, Color(0.84, 0.92, 0.94)))
	return panel


func _meta_reward_panel(settlement: Dictionary) -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "MetaRewardPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	box.add_child(UiFactory.label("局外收益", 24, Color(0.90, 0.98, 1.0)))
	box.add_child(UiFactory.label("窝囊费 +%d" % int(settlement.get("earned_currency", 0)), 22, Color(1.0, 0.9, 0.55)))
	box.add_child(UiFactory.label("当前窝囊费：%d" % int(AppRoot.meta_service.meta_state.get("owned_discomfort_currency", 0)), 20, Color(1.0, 0.9, 0.55)))
	box.add_child(UiFactory.label("最高楼层记录：%dF" % int(AppRoot.meta_service.meta_state.get("highest_floor_reached", 1)), 16, Color(0.80, 0.90, 0.92)))
	return panel


func _result_actions_panel() -> PanelContainer:
	var panel := UiFactory.panel()
	panel.name = "RunResultActionPanel"
	var box := UiFactory.vbox(8)
	panel.add_child(box)
	var menu := UiFactory.button("返回主菜单")
	menu.name = "ReturnButton"
	menu.pressed.connect(func():
		AppRoot.reset_run()
		AppRoot.flow_controller.show_scene("main_menu")
	)
	box.add_child(menu)
	var meta := UiFactory.button("查看工位成长")
	meta.name = "MetaProgressionButton"
	meta.pressed.connect(func():
		AppRoot.reset_run()
		AppRoot.flow_controller.show_scene("meta")
	)
	box.add_child(meta)
	return panel
