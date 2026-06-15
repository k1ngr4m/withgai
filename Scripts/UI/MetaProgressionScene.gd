extends Control

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFactory.fill(self)
	UiFactory.add_background(self, "res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v1.png")
	var margin := UiFactory.margin(self, 28)
	var main := UiFactory.vbox(12)
	margin.add_child(main)
	main.add_child(UiFactory.label("工位成长与职业树 | 窝囊费 %d" % int(AppRoot.meta_service.meta_state.get("owned_discomfort_currency", 0)), 30))
	var row := UiFactory.hbox(12)
	main.add_child(UiFactory.scroll(row))
	var upgrades := UiFactory.vbox(8)
	row.add_child(upgrades)
	upgrades.add_child(UiFactory.label("工位升级", 24))
	for upgrade in AppRoot.config_service.all_defs("meta_upgrades"):
		if upgrade.get("type", "") != "global_upgrade":
			continue
		upgrades.add_child(_upgrade_button(upgrade))
	var careers := UiFactory.vbox(8)
	row.add_child(careers)
	careers.add_child(UiFactory.label("职业解锁树", 24))
	for cls in AppRoot.config_service.first_playable_classes(true):
		var status: String = "可玩" if cls.get("enabled_in_first_playable", false) else "扩展占位"
		careers.add_child(UiFactory.label("%s | 难度 %d | %s\n%s" % [cls.get("name", ""), int(cls.get("recommended_difficulty", 1)), status, cls.get("summary", "")], 16, Color(0.86, 0.94, 0.94)))
	var back := UiFactory.button("返回主菜单")
	back.pressed.connect(func(): AppRoot.flow_controller.show_scene("main_menu"))
	main.add_child(back)

func _upgrade_button(upgrade: Dictionary) -> Button:
	var level: int = AppRoot.meta_service.get_upgrade_level(upgrade.get("id", ""))
	var max_level: int = int(upgrade.get("max_level", 0))
	var costs: Array = upgrade.get("cost_curve", [])
	var cost := 0 if level >= max_level else int(costs[min(level, costs.size() - 1)])
	var b: Button = UiFactory.button("%s Lv.%d/%d  花费 %d\n%s" % [upgrade.get("name", ""), level, max_level, cost, upgrade.get("description", "")])
	b.custom_minimum_size = Vector2(360, 82)
	b.disabled = level >= max_level or int(AppRoot.meta_service.meta_state.get("owned_discomfort_currency", 0)) < cost
	b.pressed.connect(func():
		AppRoot.meta_service.buy_upgrade(upgrade.get("id", ""))
		_build()
	)
	return b
