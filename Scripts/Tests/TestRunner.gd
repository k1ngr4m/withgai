extends SceneTree

const ConfigServiceScript := preload("res://Scripts/Services/ConfigService.gd")
const SaveServiceScript := preload("res://Scripts/Services/SaveService.gd")
const MetaProgressionServiceScript := preload("res://Scripts/Services/MetaProgressionService.gd")
const MapServiceScript := preload("res://Scripts/Services/MapService.gd")
const RunSessionScript := preload("res://Scripts/Services/RunSession.gd")
const ContentResolverScript := preload("res://Scripts/Services/ContentResolver.gd")
const EffectExecutorScript := preload("res://Scripts/Services/EffectExecutor.gd")
const BattleServiceScript := preload("res://Scripts/Services/BattleService.gd")
const RewardServiceScript := preload("res://Scripts/Services/RewardService.gd")

var failed := false

func _init() -> void:
	var config = ConfigServiceScript.new()
	config.load_config()
	_check(config.get_table("classes").size() >= 6, "classes loaded")
	_check(config.get_table("cards").size() >= 162, "cards loaded")
	_check(config.get_table("effect_groups").size() >= config.get_table("cards").size(), "effect groups loaded")
	_check(config.get_table("effect_entries").size() >= config.get_table("cards").size(), "effect entries loaded")
	var content = ContentResolverScript.new()
	content.call("setup", config)
	var save = SaveServiceScript.new()
	var meta = MetaProgressionServiceScript.new()
	meta.call("setup", save, config)
	var map = MapServiceScript.new()
	map.call("setup", config)
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var reward_service = RewardServiceScript.new()
	reward_service.call("setup", content, map, meta)
	_validate_main_menu_scene()
	_validate_map_scene()
	_validate_battle_scene()
	_validate_reward_scene()
	_validate_initial_boost_scene()
	_validate_shop_scene()
	_validate_event_scene()
	_validate_rest_scene()
	_validate_run_result_scene()
	_validate_card_face_ui(config)
	_validate_config_references(config, content)
	_validate_run_class_locks(config, map, meta)
	_validate_run_reset_cleanup()
	for class_id in ["backend"]:
		var run := run_session.create_new_run(class_id)
		_check(run.get("deck_state", {}).get("master_deck", []).size() == 10, "%s starter deck" % class_id)
		_check(run.get("map_state", {}).get("floors", []).size() == 6, "%s chapter map" % class_id)
		_check(run.get("map_state", {}).get("available_next_nodes", []).size() > 0, "%s available nodes" % class_id)
		_validate_class_resources(class_id)
		_validate_map_constraints(run, "%s map constraints" % class_id)
		_validate_battle(class_id, config, content, map, meta, reward_service)
	_validate_combat_mechanics(config, content, map, meta)
	_validate_enemy_intent_actions(config, content, map, meta)
	_validate_enemy_phase_scripts(config, content, map, meta)
	_validate_shop_event_rest(config, content, map, meta, reward_service)
	_validate_reward_economy(config, map, meta, reward_service)
	_validate_initial_boosts(config, content, map, meta, reward_service, save)
	_validate_save_roundtrip(config, map, meta, save)
	_validate_meta_settlement(config, map, meta)
	_validate_meta_upgrades(config, map, meta, reward_service)
	_validate_boss_progression(config, map, meta, reward_service)
	print("TEST_RESULT: %s" % ("FAILED" if failed else "PASSED"))
	quit(1 if failed else 0)

func _validate_main_menu_scene() -> void:
	var packed: PackedScene = load("res://Scenes/MainMenuScene.tscn")
	_check(packed != null, "main menu scene loads")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/MainMenuScene.gd")
	var motion_source := FileAccess.get_file_as_string("res://Scripts/UI/UiMotion.gd")
	_check(not motion_source.is_empty(), "ui motion helper exists")
	_check(motion_source.contains("static func press"), "ui motion supports button press")
	_check(motion_source.contains("static func float_text"), "ui motion supports float text")
	_check(motion_source.contains("reduce_motion"), "ui motion reads reduce motion setting")
	_check(motion_source.contains("var original_modulate := child_item.modulate"), "ui motion preserves child opacity before hand fade-in")
	_check(not motion_source.contains("tween_callback(func(): fade_in(child, duration, offset))"), "ui motion child fade-in does not tween back to transparent")
	_check(source.contains("MAIN_BG"), "main menu background configured")
	_check(source.contains("ui_main_menu_bg_v2/final.png"), "main menu uses title screen background")
	_check(source.contains("SAVE_SLOT_ICON"), "main menu save slot icon configured")
	_check(source.contains("VERSION_ICON"), "main menu version icon configured")
	_check(source.contains("TITLE_LOGO"), "main menu title logo sprite configured")
	_check(source.contains("main_menu_title_logo_v3/final.png"), "main menu uses provided title logo sprite")
	_check(source.contains("_title_logo_control"), "main menu builds title logo sprite control")
	_check(source.contains("SaveSlotWidget"), "main menu save slot widget configured")
	_check(source.contains("VersionWidget"), "main menu version widget configured")
	_check(source.contains("MainTitleLogo"), "main menu title logo configured")
	_check(source.contains("\"With Gai\""), "main menu title fallback preserves required capitalization and spacing")
	_check(not source.contains("\"withgai\""), "main menu title fallback no longer uses old lowercase title")
	_check(source.contains("VerticalMainMenu"), "main menu vertical menu configured")
	_check(source.contains("_build_title_menu_screen(_is_compact_layout())"), "main menu builds minimalist title screen")
	_check(not source.contains("left.add_child(_hero_block(false))"), "main menu desktop no longer uses old info hero")
	_check(not source.contains("root.add_child(_hero_block(true))"), "main menu compact no longer uses old info hero")
	_check(source.contains("SHORT_BREAKPOINT := 860.0"), "main menu uses compact layout on short displays")
	_check(source.contains("NewGameButton"), "main menu new game button configured")
	_check(source.contains("ContinueButton"), "main menu continue button configured")
	_check(source.contains("MetaButton"), "main menu meta button configured")
	_check(source.contains("OptionsButton"), "main menu options button configured")
	_check(source.contains("OptionsOverlay"), "main menu options overlay configured")
	_check(source.contains("MasterVolumeSlider"), "main menu master volume slider configured")
	_check(source.contains("ReduceMotionToggle"), "main menu reduce motion toggle configured")
	_check(source.contains("AmbientMotionToggle"), "main menu ambient motion toggle configured")
	_check(source.contains("ScreenShakeToggle"), "main menu screen shake toggle configured")
	_check(source.contains("_apply_saved_settings"), "main menu applies persisted settings")
	_check(source.contains("update_setting"), "main menu saves settings to meta state")
	_check(source.contains("RESUMABLE_SCENE_TAGS"), "main menu resume scene whitelist configured")
	_check(source.contains("ExitButton"), "main menu exit button configured")
	var main_menu_instance: Node = packed.instantiate()
	_check(String(main_menu_instance.call("_resume_scene_tag", "shop")) == "shop", "main menu resume keeps known scene tag")
	_check(String(main_menu_instance.call("_resume_scene_tag", "initial_boost")) == "initial_boost", "main menu resume keeps initial boost scene tag")
	_check(String(main_menu_instance.call("_resume_scene_tag", "unknown_scene")) == "map", "main menu resume falls back for unknown scene tag")
	main_menu_instance.free()
	var event_source := FileAccess.get_file_as_string("res://Scripts/UI/EventScene.gd")
	var shop_source := FileAccess.get_file_as_string("res://Scripts/UI/ShopScene.gd")
	var battle_source := FileAccess.get_file_as_string("res://Scripts/UI/BattleScene.gd")
	var reward_source := FileAccess.get_file_as_string("res://Scripts/UI/RewardScene.gd")
	var rest_source := FileAccess.get_file_as_string("res://Scripts/UI/RestScene.gd")
	var class_select_source := FileAccess.get_file_as_string("res://Scripts/UI/ClassSelectScene.gd")
	_check(event_source.contains("save_suspend"), "event scene persists prepared event state")
	_check(shop_source.contains("save_suspend"), "shop scene persists stock and purchases")
	_check(battle_source.contains("persist_current_battle"), "battle scene persists current battle before suspend")
	_check(battle_source.contains("_clear_resolved_battle"), "battle scene clears resolved battles before leaving")
	_check(battle_source.contains("battle_service.clear()"), "battle scene clears battle service state after victory or defeat")
	_check(not reward_source.contains("save_suspend(run"), "reward confirm lets flow controller save destination scene")
	_check(source.contains("app.reset_run()"), "main menu quick start clears previous run state")
	_check(source.contains("_show_scene(\"initial_boost\")"), "main menu quick start opens initial boost scene")
	_check(class_select_source.contains("AppRoot.reset_run()"), "class select start clears previous run state")
	_check(class_select_source.contains("show_scene(\"initial_boost\")"), "class select start opens initial boost scene")
	_check(class_select_source.contains("CLASS_CHARACTER_BG"), "class select uses integrated character backgrounds")
	_check(class_select_source.contains("CLASS_HEAD_ART"), "class select uses class head icons")
	_check(class_select_source.contains("ClassCharacterBackground"), "class select has full-screen character background")
	_check(class_select_source.contains("ClassThumbnailBar"), "class select has bottom thumbnail bar")
	_check(class_select_source.contains("ClassDetailPanel"), "class select has detail panel")
	_check(class_select_source.contains("ConfirmClassButton"), "class select has confirm button")
	_check(class_select_source.contains("BackButton"), "class select has back button")
	_check(class_select_source.contains("_confirm_selected_class"), "class select confirms selected class")
	_check(not class_select_source.contains("ClassHeroPanel"), "class select no longer overlays a separate hero art panel")
	_check(not class_select_source.contains("\"hr\": \"res://Resources/Art/Generated/P0/characters/char_product_manager_head_icon_v1/final.png\""), "class select HR no longer reuses product manager head icon")
	_check(load("res://Resources/Art/Generated/P0/backgrounds/ui_class_select_backend_character_bg_v1/final.png") != null, "class select backend character background loads")
	_check(load("res://Resources/Art/Generated/P0/characters/char_hr_head_icon_v1/final.png") != null, "class select HR head icon loads")
	_check(event_source.contains("_go_main_menu"), "event scene has pause-to-menu action")
	_check(shop_source.contains("_go_main_menu"), "shop scene has pause-to-menu action")
	_check(reward_source.contains("_go_main_menu"), "reward scene has pause-to-menu action")
	_check(rest_source.contains("_go_main_menu"), "rest scene has pause-to-menu action")
	_check(rest_source.contains("_clear_children"), "rest scene clears old UI before rebuilding")
	_check(rest_source.contains("back.pressed.connect(_build_main)"), "rest scene upgrade back button rebuilds clean main view")
	_check(not rest_source.contains("back.pressed.connect(_ready)"), "rest scene upgrade back button does not stack ready UI")
	var main_menu_assets := [
		"res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v2/final.png",
		"res://Resources/Art/Generated/P0/ui/main_menu_save_icon_v1/final.png",
		"res://Resources/Art/Generated/P0/ui/main_menu_version_icon_v1/final.png",
		"res://Resources/Art/Generated/P0/ui/main_menu_title_logo_v3/final.png",
	]
	for asset_path in main_menu_assets:
		_check(load(asset_path) != null, "%s main menu asset loads" % asset_path)
	var main_menu_prompt_files := [
		"res://Resources/Art/Generated/P0/backgrounds/ui_main_menu_bg_v2/prompt-used.txt",
		"res://Resources/Art/Generated/P0/ui/main_menu_save_icon_v1/prompt-used.txt",
		"res://Resources/Art/Generated/P0/ui/main_menu_version_icon_v1/prompt-used.txt",
		"res://Resources/Art/Generated/P0/ui/main_menu_title_logo_v3/prompt-used.txt",
	]
	for prompt_path in main_menu_prompt_files:
		_check(FileAccess.file_exists(prompt_path), "%s main menu prompt saved" % prompt_path)


func _validate_map_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/MapScene.tscn"), "map scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/MapScene.gd")
	_check(source.contains("ChapterHeader"), "map scene chapter header configured")
	_check(source.contains("MapGraphPanel"), "map scene graph panel configured")
	_check(source.contains("MapLegendPanel"), "map scene legend panel configured")
	_check(source.contains("FloorInfoPanel"), "map scene floor info panel configured")
	_check(source.contains("NodeDetailPanel"), "map scene node detail panel configured")
	_check(source.contains("ResumeButton"), "map scene confirm enter button configured")
	_check(source.contains("_select_node"), "map scene supports node preview selection")
	_check(source.contains("_enter_selected_node"), "map scene confirms selected node before entering")
	_check(source.contains("_node_reward_hint"), "map scene explains node reward expectations")
	_check(source.contains("_add_dashed_route"), "map scene draws dashed map routes")
	_check(source.contains("_map_node_button"), "map scene uses sprite node buttons")


func _validate_battle_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/BattleScene.tscn"), "battle scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/BattleScene.gd")
	var animator_source := FileAccess.get_file_as_string("res://Scripts/UI/FrameAnimator.gd")
	_check(source.contains("BattleHeader"), "battle scene header configured")
	_check(source.contains("PlayerArea"), "battle scene player area configured")
	_check(source.contains("CombatStage"), "battle scene combat stage configured")
	_check(source.contains("PlayerActorPanel"), "battle scene player actor panel configured")
	_check(source.contains("ResourcePanel"), "battle scene class resource panel configured")
	_check(source.contains("EnemyArea"), "battle scene enemy area configured")
	_check(source.contains("IntentArea"), "battle scene intent area configured")
	_check(source.contains("HandPanel"), "battle scene hand panel configured")
	_check(source.contains("HandArea"), "battle scene hand area configured")
	_check(source.contains("HandScroll"), "battle scene reserves visible hand scroll area")
	_check(source.contains("custom_minimum_size = Vector2(0, 318)"), "battle scene hand panel is tall enough for card faces")
	_check(source.contains("BattleLogPanel"), "battle scene log panel configured")
	_check(source.contains("EndTurnButton"), "battle scene end turn button configured")
	_check(source.contains("draw_pile"), "battle scene resource panel shows pile counts")
	_check(source.contains("FrameAnimator"), "battle scene uses animated enemy art")
	_check(source.contains("visual_events"), "battle scene consumes enemy animation events")
	_check(source.contains("_battle_snapshot"), "battle scene snapshots motion state")
	_check(source.contains("_play_visual_events"), "battle scene plays extended visual events")
	_check(source.contains("PlayerAnimator"), "battle scene supports player animation preview")
	_check(animator_source.contains("play_action"), "frame animator supports action playback")
	_check(animator_source.contains("_play_idle()"), "frame animator falls back to idle")


func _validate_reward_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/RewardScene.tscn"), "reward scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/RewardScene.gd")
	_check(source.contains("RewardHeader"), "reward scene header configured")
	_check(source.contains("CurrencyPanel"), "reward scene currency panel configured")
	_check(source.contains("CardChoicePanel"), "reward scene card choice panel configured")
	_check(source.contains("RelicChoicePanel"), "reward scene relic choice panel configured")
	_check(source.contains("RewardConfirmPanel"), "reward scene confirm panel configured")
	_check(source.contains("ConfirmRewardButton"), "reward scene confirm reward button configured")
	_check(source.contains("_reward_selection_summary"), "reward scene summarizes current selection")
	_check(source.contains("SkipCardButton"), "reward scene explicit card skip button configured")
	_check(source.contains("SkipRelicButton"), "reward scene explicit relic skip button configured")


func _validate_initial_boost_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/InitialBoostScene.tscn"), "initial boost scene resource exists")
	var packed: PackedScene = load("res://Scenes/InitialBoostScene.tscn")
	_check(packed != null, "initial boost scene loads")
	var instance: Node = packed.instantiate()
	_check(instance != null, "initial boost scene instantiates")
	instance.free()
	var source := FileAccess.get_file_as_string("res://Scripts/UI/InitialBoostScene.gd")
	var flow_source := FileAccess.get_file_as_string("res://Scripts/Services/FlowController.gd")
	_check(flow_source.contains("\"initial_boost\""), "flow controller registers initial boost scene")
	_check(source.contains("InitialBoostHeader"), "initial boost scene header configured")
	_check(source.contains("InitialBoostOptionList"), "initial boost option list configured")
	_check(source.contains("InitialBoostButton_"), "initial boost option buttons configured")
	_check(source.contains("InitialBoostIcon"), "initial boost option icons configured")
	_check(source.contains("InitialBoostDescription"), "initial boost descriptions configured")
	_check(source.contains("accept_initial_boost"), "initial boost scene accepts chosen boost")


func _validate_shop_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/ShopScene.tscn"), "shop scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/ShopScene.gd")
	_check(source.contains("ShopHeader"), "shop scene header configured")
	_check(source.contains("PlayerCurrencyPanel"), "shop scene currency panel configured")
	_check(source.contains("ShopStockPanel"), "shop scene stock panel configured")
	_check(source.contains("DeckOperationPanel"), "shop scene deck operation panel configured")
	_check(source.contains("RefreshButton"), "shop scene refresh button configured")
	_check(source.contains("RemoveSelectedCardButton"), "shop scene remove card button configured")
	_check(source.contains("ShopCardButton"), "shop scene card stock buttons configured")
	_check(source.contains("ShopRelicButton"), "shop scene relic stock buttons configured")
	_check(source.contains("DeckRemoveGrid"), "shop scene deck remove grid configured")


func _validate_event_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/EventScene.tscn"), "event scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/EventScene.gd")
	_check(source.contains("EventTextPanel"), "event scene text panel configured")
	_check(source.contains("OptionListPanel"), "event scene option list panel configured")
	_check(source.contains("ResultPanel"), "event scene result panel configured")
	_check(source.contains("ConfirmEventResultButton"), "event scene result confirm button configured")
	_check(source.contains("EventOptionButton"), "event scene option buttons configured")
	_check(source.contains("_event_snapshot"), "event scene snapshots before/after state")
	_check(source.contains("_format_result_delta"), "event scene formats result delta")
	_check(source.contains("\"map\" if _resolved else \"event\""), "event scene resolved result saves as map")


func _validate_rest_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/RestScene.tscn"), "rest scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/RestScene.gd")
	_check(source.contains("RestHeader"), "rest scene header configured")
	_check(source.contains("RestStatusPanel"), "rest scene status panel configured")
	_check(source.contains("RestChoicePanel"), "rest scene choice panel configured")
	_check(source.contains("RecoverButton"), "rest scene recover button configured")
	_check(source.contains("UpgradeButton"), "rest scene upgrade button configured")
	_check(source.contains("UpgradeChoicePanel"), "rest scene upgrade choice panel configured")
	_check(source.contains("UpgradeCardButton"), "rest scene upgrade card buttons configured")
	_check(source.contains("_rest_recover_preview"), "rest scene previews recovery amount")
	_check(source.contains("_eligible_upgrade_count"), "rest scene counts eligible upgrades")


func _validate_run_result_scene() -> void:
	_check(ResourceLoader.exists("res://Scenes/RunResultScene.tscn"), "run result scene resource exists")
	var source := FileAccess.get_file_as_string("res://Scripts/UI/RunResultScene.gd")
	_check(source.contains("RunResultHeader"), "run result scene header configured")
	_check(source.contains("ResultSummaryPanel"), "run result summary panel configured")
	_check(source.contains("MetaRewardPanel"), "run result meta reward panel configured")
	_check(source.contains("ReturnButton"), "run result return button configured")
	_check(source.contains("MetaProgressionButton"), "run result meta progression button configured")
	_check(source.contains("_has_result_run"), "run result scene guards empty run state")
	_check(source.contains("clear_suspend"), "run result clears suspend save")
	_check(source.contains("settle_run"), "run result settles meta progression")


func _validate_card_face_ui(config) -> void:
	_check(ResourceLoader.exists("res://Scripts/UI/CardFaceButton.gd"), "card face button script exists")
	var card_source := FileAccess.get_file_as_string("res://Scripts/UI/CardFaceButton.gd")
	var factory_source := FileAccess.get_file_as_string("res://Scripts/UI/UiFactory.gd")
	_check(card_source.contains("class_name CardFaceButton"), "card face button class configured")
	for node_name in ["CardCost", "CardTitle", "CardArt", "CardType", "CardDescription", "CardBadge"]:
		_check(card_source.contains(node_name), "%s node configured" % node_name)
	_check(card_source.contains("TYPE_NAMES"), "card face maps card types")
	_check(card_source.contains("_trim_description"), "card face trims repeated card names")
	_check(factory_source.contains("CardFaceButtonScript"), "ui factory preloads card face button")
	_check(factory_source.contains("setup_card"), "ui factory configures card face button")
	var card_button = load("res://Scripts/UI/CardFaceButton.gd").new()
	card_button.custom_minimum_size = Vector2(178, 252)
	card_button.call("setup_card", {
		"id": "test_card",
		"name": "测试牌",
		"type": "skill",
		"cost": 1,
		"description": "测试牌：获得防线。",
		"art_path": "",
	}, { "badge_text": "已选", "selected": true })
	for node_name in ["CardCost", "CardTitle", "CardArt", "CardType", "CardDescription", "CardBadge"]:
		_check(card_button.find_child(node_name, true, false) != null, "%s node instantiates" % node_name)
	var desc_label := card_button.find_child("CardDescription", true, false) as Label
	_check(desc_label != null and desc_label.text == "获得防线。", "card face shows trimmed description text")
	_check(card_button.get_combined_minimum_size().y <= 252.0, "card face fits battle hand height")
	card_button.free()
	var battle_source := FileAccess.get_file_as_string("res://Scripts/UI/BattleScene.gd")
	var reward_source := FileAccess.get_file_as_string("res://Scripts/UI/RewardScene.gd")
	var shop_source := FileAccess.get_file_as_string("res://Scripts/UI/ShopScene.gd")
	var rest_source := FileAccess.get_file_as_string("res://Scripts/UI/RestScene.gd")
	_check(not battle_source.contains("%s [%s]\\n%s\\n%s"), "battle cards no longer use multiline button text")
	_check(not reward_source.contains("%s%s\\n%s\\n%s"), "reward cards no longer use multiline button text")
	_check(not shop_source.contains("买卡 %d\\n%s\\n%s"), "shop cards no longer use multiline button text")
	_check(not rest_source.contains("%s%s\\n%s"), "rest upgrade cards no longer use multiline button text")
	for card in config.all_defs("cards"):
		if not bool(card.get("enabled_in_first_playable", false)):
			continue
		var art_path := String(card.get("art_path", ""))
		_check(not art_path.is_empty(), "%s enabled card has art path" % String(card.get("id", "")))
		_check(load(art_path) != null, "%s enabled card art loads" % String(card.get("id", "")))


func _validate_config_references(config, content) -> void:
	_check(not config.get_def("classes", "hr").get("enabled_in_first_playable", true), "hr remains placeholder")
	_check(content.cards_for_run_class("hr", true).is_empty(), "hr excluded from run card pool")
	_check(not content.reward_profile("reward_default").is_empty(), "default reward profile exists")
	_check(not content.shop_pool("shop_default").is_empty(), "default shop pool exists")
	_check(config.get_table("initial_boosts").size() >= 8, "initial boost table loaded")
	_check(content.initial_boosts_for_run_class("backend").size() >= 8, "backend initial boost pool loaded")
	for boost in config.all_defs("initial_boosts"):
		_check(not String(boost.get("name", "")).is_empty(), "%s initial boost has name" % String(boost.get("id", "")))
		_check(int(boost.get("weight", 0)) > 0, "%s initial boost has weight" % String(boost.get("id", "")))
		var boost_art_path := String(boost.get("art_path", ""))
		_check(not boost_art_path.is_empty(), "%s initial boost has icon" % String(boost.get("id", "")))
		_check(load(boost_art_path) != null, "%s initial boost icon loads" % String(boost.get("id", "")))
	for class_id in ["backend", "frontend", "tester", "algorithm", "product_manager"]:
		var cls: Dictionary = content.class_def(class_id)
		_check(not content.relic_def(cls.get("starter_relic_id", "")).is_empty(), "%s starter relic resolves" % class_id)
		for card_id in cls.get("starter_deck", []):
			_check(not content.card_def(card_id).is_empty(), "%s starter card resolves" % card_id)
	_check(content.is_run_class_enabled("backend"), "backend enabled as run class")
	var backend_pool: Array = content.cards_for_run_class("backend", true)
	_check(backend_pool.size() >= 30, "backend content pool has cards")
	var has_hr_card := false
	for card in backend_pool:
		if String(card.get("id", "")).begins_with("card_hr_"):
			has_hr_card = true
	_check(not has_hr_card, "backend pool excludes hr cards")
	for class_id in ["frontend", "tester", "algorithm", "product_manager", "hr"]:
		_check(not content.is_run_class_enabled(class_id), "%s locked as placeholder run class" % class_id)
		var pool: Array = content.cards_for_run_class(class_id, true)
		_check(pool.is_empty(), "%s excluded from run card pool" % class_id)
		_check(content.relics_for_run_class(class_id, true).is_empty(), "%s excluded from run relic pool" % class_id)
	var enabled_cards_missing_group := 0
	var enabled_cards_missing_entries := 0
	for card in config.all_defs("cards"):
		if not card.get("enabled_in_first_playable", false):
			continue
		var group_id := String(card.get("effect_group_id", ""))
		if group_id.is_empty():
			enabled_cards_missing_group += 1
		if content.effect_entries(group_id).is_empty():
			enabled_cards_missing_entries += 1
	_check(enabled_cards_missing_group == 0, "enabled cards have effect group ids")
	_check(enabled_cards_missing_entries == 0, "enabled card effect entries resolve")
	var orphan_effect_entries := 0
	for entry in config.all_defs("effect_entries"):
		if config.get_def("effect_groups", entry.get("effect_group_id", "")).is_empty():
			orphan_effect_entries += 1
	_check(orphan_effect_entries == 0, "effect entries resolve parent groups")

	var enemies_missing_intents := 0
	var enemies_missing_rewards := 0
	var enemies_missing_art := 0
	var enemies_unloadable_art := 0
	var enemies_missing_animation := 0
	var enemies_unloadable_animation := 0
	for enemy in config.all_defs("enemies"):
		if content.intent_entries_for_enemy(enemy.get("id", "")).is_empty():
			enemies_missing_intents += 1
		if content.reward_profile(enemy.get("reward_profile_id", "")).is_empty():
			enemies_missing_rewards += 1
		var enemy_art_path := String(enemy.get("art_path", ""))
		if enemy_art_path.is_empty():
			enemies_missing_art += 1
		elif load(enemy_art_path) == null:
			enemies_unloadable_art += 1
		for animation_field in ["idle_frame_paths", "attack_frame_paths", "hurt_frame_paths"]:
			var frame_paths: Array = enemy.get(animation_field, [])
			if frame_paths.is_empty():
				enemies_missing_animation += 1
				continue
			for frame_path in frame_paths:
				if load(String(frame_path)) == null:
					enemies_unloadable_animation += 1
	_check(enemies_missing_intents == 0, "enemy intent groups resolve")
	_check(enemies_missing_rewards == 0, "enemy reward profiles resolve")
	_check(enemies_missing_art == 0, "enemy art paths configured")
	_check(enemies_unloadable_art == 0, "enemy art paths load")
	_check(enemies_missing_animation == 0, "enemy animation frame paths configured")
	_check(enemies_unloadable_animation == 0, "enemy animation frame paths load")
	var encounter_missing_enemies := 0
	for encounter in config.all_defs("encounters"):
		for enemy_id in encounter.get("enemy_ids", []):
			if content.enemy_def(enemy_id).is_empty():
				encounter_missing_enemies += 1
	_check(encounter_missing_enemies == 0, "encounter enemies resolve")
	for card_id in ["card_status_option_promise", "card_status_meeting_minutes", "card_curse_next_year_promotion"]:
		var pollution_card: Dictionary = content.card_def(card_id)
		_check(not pollution_card.is_empty(), "%s pollution card resolves" % card_id)
		_check(not content.effect_entries(pollution_card.get("effect_group_id", "")).is_empty(), "%s pollution card has effects" % card_id)
	var smoke_test_entries: Array = content.effect_entries(content.card_def("card_tester_smoke_test").get("effect_group_id", ""))
	var smoke_test_blocks := false
	var smoke_test_observes := false
	var smoke_test_adds_diff := false
	for smoke_test_entry in smoke_test_entries:
		if smoke_test_entry.get("effect_type", "") == "gain_block" and int(smoke_test_entry.get("params", {}).get("amount", 0)) > 0:
			smoke_test_blocks = true
		if smoke_test_entry.get("effect_type", "") == "observe_intent" and smoke_test_entry.get("target_type", "") == "all_enemies":
			smoke_test_observes = true
		if smoke_test_entry.get("effect_type", "") == "add_diff":
			smoke_test_adds_diff = true
	_check(smoke_test_blocks, "tester smoke test grants block")
	_check(smoke_test_observes, "tester smoke test observes next intent")
	_check(not smoke_test_adds_diff, "tester smoke test does not add diff")
	var circuit_breaker_entries: Array = content.effect_entries(content.card_def("card_backend_circuit_breaker").get("effect_group_id", ""))
	var circuit_breaker_scales := false
	for entry in circuit_breaker_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "circuit_breaker" and int(params.get("amount", 0)) > 0 and int(params.get("service_block_amount", 0)) > 0 and int(params.get("service_cache_amount", 0)) > 0 and int(params.get("heavy_attack_threshold", 0)) > 0 and int(params.get("heavy_block_amount", 0)) > 0:
			circuit_breaker_scales = true
	_check(circuit_breaker_scales, "backend circuit breaker scales with service and heavy attack")
	var service_degrade_entries: Array = content.effect_entries(content.card_def("card_backend_service_degrade").get("effect_group_id", ""))
	var service_degrade_reduces_intent := false
	for entry in service_degrade_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "service_degrade" and int(params.get("amount", 0)) > 0 and int(params.get("block_per_service", 0)) > 0 and int(params.get("cache_if_service", 0)) > 0:
			service_degrade_reduces_intent = true
	_check(service_degrade_reduces_intent, "backend service degrade lowers damage and scales with service")
	var trace_chain_entries: Array = content.effect_entries(content.card_def("card_backend_trace_chain").get("effect_group_id", ""))
	var trace_chain_fetches_service := false
	for entry in trace_chain_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "fetch_service_card" and int(params.get("amount", 0)) > 0:
			trace_chain_fetches_service = true
	_check(trace_chain_fetches_service, "backend trace chain fetches service cards")
	var api_gateway_entries: Array = content.effect_entries(content.card_def("card_backend_api_gateway").get("effect_group_id", ""))
	var api_gateway_applies_status := false
	for entry in api_gateway_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "api_gateway":
			api_gateway_applies_status = true
	_check(api_gateway_applies_status, "backend api gateway applies api gateway status")
	var redis_entries: Array = content.effect_entries(content.card_def("card_backend_redis_warmup").get("effect_group_id", ""))
	var redis_adds_cache := false
	var redis_applies_warmup := false
	for redis_entry in redis_entries:
		var redis_entry_params: Dictionary = redis_entry.get("params", {})
		if redis_entry.get("effect_type", "") == "add_cache" and int(redis_entry_params.get("amount", 0)) >= 3:
			redis_adds_cache = true
		if redis_entry.get("effect_type", "") == "apply_status" and redis_entry_params.get("status_id", "") == "redis_warmup":
			redis_applies_warmup = true
	_check(redis_adds_cache, "backend redis warmup adds large cache")
	_check(redis_applies_warmup, "backend redis warmup applies next-turn warmup status")
	var message_queue_entries: Array = content.effect_entries(content.card_def("card_backend_message_queue").get("effect_group_id", ""))
	var message_queue_applies_requests := false
	for message_queue_entry in message_queue_entries:
		var message_queue_params: Dictionary = message_queue_entry.get("params", {})
		if message_queue_entry.get("effect_type", "") == "apply_status" and message_queue_params.get("status_id", "") == "request_queue" and int(message_queue_params.get("amount", 0)) >= 3:
			message_queue_applies_requests = true
	_check(message_queue_applies_requests, "backend message queue applies request queue")
	var sharding_entries: Array = content.effect_entries(content.card_def("card_backend_sharding").get("effect_group_id", ""))
	var sharding_applies_status := false
	for sharding_entry in sharding_entries:
		var sharding_params: Dictionary = sharding_entry.get("params", {})
		if sharding_entry.get("effect_type", "") == "apply_status" and sharding_params.get("status_id", "") == "sharding":
			sharding_applies_status = true
	_check(sharding_applies_status, "backend sharding applies sharding status")
	var traffic_entries: Array = content.effect_entries(content.card_def("card_backend_traffic_shaping").get("effect_group_id", ""))
	var traffic_shapes_damage := false
	for traffic_entry in traffic_entries:
		var traffic_params: Dictionary = traffic_entry.get("params", {})
		if traffic_entry.get("effect_type", "") == "add_cache" and bool(traffic_params.get("from_damage_taken_this_turn", false)):
			traffic_shapes_damage = true
	_check(traffic_shapes_damage, "backend traffic shaping converts damage taken to cache")
	var component_reuse_art := String(content.card_def("card_frontend_component_reuse").get("art_path", ""))
	_check(component_reuse_art.ends_with("card_illust_frontend_component_reuse_v1/final.png"), "frontend component reuse card art configured")
	var pixel_tap_entries: Array = content.effect_entries(content.card_def("card_frontend_pixel_tap").get("effect_group_id", ""))
	var pixel_tap_has_combo_bonus := false
	for entry in pixel_tap_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("cards_played_bonus_threshold", 0)) == 2 and int(params.get("bonus_amount", 0)) > 0:
			pixel_tap_has_combo_bonus = true
	_check(pixel_tap_has_combo_bonus, "frontend pixel tap gains played-card combo damage")
	var flex_layout_entries: Array = content.effect_entries(content.card_def("card_frontend_flex_layout").get("effect_group_id", ""))
	var flex_layout_blocks := false
	var flex_layout_adds_component := false
	var flex_layout_adds_style := false
	for entry in flex_layout_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "gain_block" and int(params.get("amount", 0)) > 0:
			flex_layout_blocks = true
		if entry.get("effect_type", "") == "add_component" and int(params.get("amount", 0)) > 0:
			flex_layout_adds_component = true
		if entry.get("effect_type", "") == "add_style_layer":
			flex_layout_adds_style = true
	_check(flex_layout_blocks, "frontend flex layout grants block")
	_check(flex_layout_adds_component, "frontend flex layout creates component")
	_check(not flex_layout_adds_style, "frontend flex layout does not add style layer")
	var slice_sprint_entries: Array = content.effect_entries(content.card_def("card_frontend_slice_sprint").get("effect_group_id", ""))
	var slice_sprint_draws := false
	var slice_sprint_adds_style := false
	var slice_sprint_blocks := false
	var slice_sprint_adds_component := false
	for entry in slice_sprint_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "draw_cards" and int(params.get("amount", 0)) > 0:
			slice_sprint_draws = true
		if entry.get("effect_type", "") == "add_style_layer" and int(params.get("amount", 0)) > 0:
			slice_sprint_adds_style = true
		if entry.get("effect_type", "") == "gain_block":
			slice_sprint_blocks = true
		if entry.get("effect_type", "") == "add_component":
			slice_sprint_adds_component = true
	_check(slice_sprint_draws, "frontend slice sprint draws")
	_check(slice_sprint_adds_style, "frontend slice sprint adds style layer")
	_check(not slice_sprint_blocks, "frontend slice sprint does not grant block")
	_check(not slice_sprint_adds_component, "frontend slice sprint does not create component")
	var component_reuse_entries: Array = content.effect_entries(content.card_def("card_frontend_component_reuse").get("effect_group_id", ""))
	var component_reuse_requires_component := false
	for entry in component_reuse_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "add_component" and bool(params.get("requires_existing_component", false)) and bool(params.get("draw_if_success", false)):
			component_reuse_requires_component = true
	_check(component_reuse_requires_component, "frontend component reuse requires component and draws")
	var hotfix_entries: Array = content.effect_entries(content.card_def("card_frontend_hotfix_style").get("effect_group_id", ""))
	var hotfix_applies_status := false
	for entry in hotfix_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "hotfix_style":
			hotfix_applies_status = true
	_check(hotfix_applies_status, "frontend hotfix style applies hotfix status")
	_check(config.get_def("statuses", "hotfix_style").get("timing_hooks", []).has("deal_damage"), "hotfix style declares damage hook")
	_check(config.get_def("statuses", "hotfix_style").get("timing_hooks", []).has("round_end"), "hotfix style declares round end hook")
	_check(bool(config.get_def("statuses", "hotfix_style").get("is_hidden", false)), "hotfix style is hidden")
	var hotfix_params: Dictionary = config.get_def("statuses", "hotfix_style").get("params", {})
	_check(int(hotfix_params.get("style_layer_amount", 0)) > 0, "hotfix style config has style layer amount")
	var pixel_align_entries: Array = content.effect_entries(content.card_def("card_frontend_pixel_align").get("effect_group_id", ""))
	var pixel_align_checks_component := false
	for entry in pixel_align_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "pixel_align" and int(params.get("amount", 0)) > 0 and int(params.get("bonus_amount", 0)) > 0:
			pixel_align_checks_component = true
	_check(pixel_align_checks_component, "frontend pixel align has component bonus")
	_check(config.get_def("statuses", "compatibility_patch").get("timing_hooks", []).has("deal_damage"), "compatibility patch declares damage hook")
	_check(config.get_def("statuses", "compatibility_patch").get("timing_hooks", []).has("round_end"), "compatibility patch declares round end hook")
	_check(bool(config.get_def("statuses", "compatibility_patch").get("is_hidden", false)), "compatibility patch is hidden")
	var compat_entries: Array = content.effect_entries(content.card_def("card_frontend_compat_patch").get("effect_group_id", ""))
	var compat_cleanses := false
	var compat_preserves_style := false
	for entry in compat_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "cleanse_debuff" and int(params.get("amount", 0)) > 0:
			compat_cleanses = true
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "compatibility_patch":
			compat_preserves_style = true
	_check(compat_cleanses, "frontend compatibility patch cleanses a debuff")
	_check(compat_preserves_style, "frontend compatibility patch preserves style layers")
	var state_boost_entries: Array = content.effect_entries(content.card_def("card_frontend_state_boost").get("effect_group_id", ""))
	var state_boost_applies_status := false
	for entry in state_boost_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "state_boost":
			state_boost_applies_status = true
	_check(state_boost_applies_status, "frontend state boost applies state boost status")
	var vue_suite_entries: Array = content.effect_entries(content.card_def("card_frontend_vue_suite").get("effect_group_id", ""))
	var vue_suite_applies_status := false
	for entry in vue_suite_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "vue_suite":
			vue_suite_applies_status = true
	_check(vue_suite_applies_status, "frontend vue suite applies vue suite status")
	var motion_entries: Array = content.effect_entries(content.card_def("card_frontend_motion_overload").get("effect_group_id", ""))
	var motion_scales_with_play_count := false
	for entry in motion_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("cards_played_multiplier", 0)) > 0:
			motion_scales_with_play_count = true
	_check(motion_scales_with_play_count, "frontend motion overload scales with cards played")
	_check(config.get_def("statuses", "first_screen_optimization").get("timing_hooks", []).has("card_cost"), "first screen optimization declares card cost hook")
	_check(config.get_def("statuses", "first_screen_optimization").get("timing_hooks", []).has("round_end"), "first screen optimization declares round end hook")
	var first_screen_params: Dictionary = config.get_def("statuses", "first_screen_optimization").get("params", {})
	_check(int(first_screen_params.get("cost_reduction_amount", 0)) > 0, "first screen optimization config has cost reduction amount")
	var first_screen_entries: Array = content.effect_entries(content.card_def("card_frontend_first_screen").get("effect_group_id", ""))
	var first_screen_applies_discount := false
	for entry in first_screen_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "first_screen_optimization" and int(params.get("amount", 0)) >= 2:
			first_screen_applies_discount = true
	_check(first_screen_applies_discount, "frontend first screen optimization discounts two cards")
	var crash_entries: Array = content.effect_entries(content.card_def("card_frontend_crash_animation").get("effect_group_id", ""))
	var crash_consumes_style_layers := false
	for entry in crash_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and bool(params.get("style_layer_hits", false)) and bool(params.get("consume_all_style_layers", false)):
			crash_consumes_style_layers = true
	_check(crash_consumes_style_layers, "frontend crash animation consumes style layers for hits")
	var circuit_breaker_art := String(content.card_def("card_backend_circuit_breaker").get("art_path", ""))
	_check(circuit_breaker_art.ends_with("card_illust_backend_circuit_breaker_v1/final.png"), "backend circuit breaker card art auto configured")
	var gpu_relic: Dictionary = content.relic_def("relic_gpu_training_card")
	_check(not gpu_relic.is_empty(), "gpu training card relic resolves")
	_check(gpu_relic.get("allowed_classes", []).has("algorithm"), "gpu training card belongs to algorithm")
	_check(gpu_relic.get("trigger_list", []).has("add_compute"), "gpu training card declares compute trigger")
	var meeting_room_relic: Dictionary = content.relic_def("relic_pm_meeting_room_claim")
	_check(not meeting_room_relic.is_empty(), "meeting room claim relic resolves")
	_check(meeting_room_relic.get("allowed_classes", []).has("product_manager"), "meeting room claim belongs to product manager")
	_check(meeting_room_relic.get("trigger_list", []).has("apply_status"), "meeting room claim declares status trigger")
	var frontend_card_art_slugs := {
		"card_frontend_component_reuse": "frontend_component_reuse",
		"card_frontend_state_boost": "frontend_state_boost",
		"card_frontend_motion_overload": "frontend_motion_overload",
		"card_frontend_hotfix_style": "frontend_hotfix_style",
		"card_frontend_pixel_align": "frontend_pixel_alignment",
		"card_frontend_compat_patch": "frontend_compat_patch",
		"card_frontend_vue_suite": "frontend_vue_suite",
		"card_frontend_css_override": "frontend_css_override",
		"card_frontend_first_screen": "frontend_first_screen_opt",
		"card_frontend_crash_animation": "frontend_crash_animation",
	}
	for card_id in frontend_card_art_slugs.keys():
		var art_path := String(content.card_def(card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % String(frontend_card_art_slugs[card_id])), "%s frontend card art configured" % card_id)
		_check(load(art_path) != null, "%s frontend card art loads" % card_id)
	var tester_card_art_slugs := [
		"card_tester_defect_log",
		"card_tester_smoke_test",
		"card_tester_repro_steps",
		"card_tester_regression_confirm",
		"card_tester_boundary_check",
		"card_tester_auto_regression",
		"card_tester_bug_upgrade",
		"card_tester_case_matrix",
		"card_tester_92_bugs",
		"card_tester_report_lock",
	]
	for card_id in tester_card_art_slugs:
		var tester_card_id := String(card_id)
		var art_path := String(content.card_def(tester_card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % tester_card_id.trim_prefix("card_")), "%s tester card art configured" % tester_card_id)
		_check(load(art_path) != null, "%s tester card art loads" % tester_card_id)
	var algorithm_card_art_slugs := [
		"card_algo_heuristic_search",
		"card_algo_dynamic_programming",
		"card_algo_complexity_burst",
		"card_algo_pruning",
		"card_algo_local_opt",
		"card_algo_big_o_compress",
		"card_algo_monte_carlo",
		"card_algo_matrix_mul",
		"card_algo_astar",
		"card_algo_global_optimum",
	]
	for card_id in algorithm_card_art_slugs:
		var algorithm_card_id := String(card_id)
		var art_path := String(content.card_def(algorithm_card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % algorithm_card_id.trim_prefix("card_")), "%s algorithm card art configured" % algorithm_card_id)
		_check(load(art_path) != null, "%s algorithm card art loads" % algorithm_card_id)
	var product_manager_card_art_slugs := {
		"card_pm_change_wording": "pm_change_request",
		"card_pm_review": "pm_review",
		"card_pm_delay_meeting": "pm_delay_meeting",
		"card_pm_priority_top": "pm_priority_top",
		"card_pm_milestone_split": "pm_milestone_split",
		"card_pm_scope_spread": "pm_scope_spread",
		"card_pm_message_align": "pm_message_align",
		"card_pm_extra_requirement": "pm_extra_requirement",
		"card_pm_align_all": "pm_align_all",
		"card_pm_roadmap": "pm_roadmap",
	}
	for card_id in product_manager_card_art_slugs.keys():
		var art_path := String(content.card_def(card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % String(product_manager_card_art_slugs[card_id])), "%s product manager card art configured" % card_id)
		_check(load(art_path) != null, "%s product manager card art loads" % card_id)
	var shared_card_art_slugs := [
		"card_shared_keyboard_smash",
		"card_shared_stapler_burst",
		"card_shared_noise_cancel",
		"card_shared_coffee_boost",
		"card_shared_toilet_break",
		"card_shared_desk_inspection",
		"card_shared_rollback",
		"card_shared_standup",
		"card_shared_clock_out",
		"card_shared_hotfix_patch",
		"card_shared_badge_throw",
		"card_shared_meeting_mute",
	]
	for card_id in shared_card_art_slugs:
		var shared_card_id := String(card_id)
		var art_path := String(content.card_def(shared_card_id).get("art_path", ""))
		_check(art_path.ends_with("card_illust_%s_v1/final.png" % shared_card_id.trim_prefix("card_")), "%s shared card art configured" % shared_card_id)
		_check(load(art_path) != null, "%s shared card art loads" % shared_card_id)
	var cards_with_art := 0
	var missing_card_art_paths := 0
	for card in config.all_defs("cards"):
		var art_path := String(card.get("art_path", ""))
		if not art_path.is_empty():
			cards_with_art += 1
			if load(art_path) == null:
				missing_card_art_paths += 1
	_check(cards_with_art >= 61, "existing matching card art assets are wired")
	_check(missing_card_art_paths == 0, "configured card art paths load")
	_check(config.get_def("statuses", "anxiety").get("timing_hooks", []).has("round_start"), "anxiety declares round start hook")
	_check(config.get_def("statuses", "overtime").get("timing_hooks", []).has("round_start"), "overtime declares round start hook")
	_check(config.get_def("statuses", "weak").get("timing_hooks", []).has("deal_damage"), "weak declares damage hook")
	_check(config.get_def("statuses", "vulnerable").get("timing_hooks", []).has("damage_taken"), "vulnerable declares damage taken hook")
	_check(config.get_def("statuses", "style_layer").get("timing_hooks", []).has("deal_damage"), "style layer declares damage hook")
	_check(config.get_def("statuses", "api_gateway").get("timing_hooks", []).has("round_start"), "api gateway declares round start hook")
	var api_gateway_params: Dictionary = config.get_def("statuses", "api_gateway").get("params", {})
	_check(int(api_gateway_params.get("block_amount", 0)) > 0, "api gateway config has block amount")
	_check(int(api_gateway_params.get("service_threshold", 0)) == 2, "api gateway config has service threshold")
	_check(int(api_gateway_params.get("draw_amount", 0)) > 0, "api gateway config has draw amount")
	_check(config.get_def("statuses", "redis_warmup").get("timing_hooks", []).has("round_start"), "redis warmup declares round start hook")
	var redis_params: Dictionary = config.get_def("statuses", "redis_warmup").get("params", {})
	_check(int(redis_params.get("cost_reduction_amount", 0)) > 0, "redis warmup config has cost reduction amount")
	_check(config.get_def("statuses", "cost_reduction").get("timing_hooks", []).has("card_cost"), "cost reduction declares card cost hook")
	_check(config.get_def("statuses", "request_queue").get("timing_hooks", []).has("round_end"), "request queue declares round end hook")
	var request_params: Dictionary = config.get_def("statuses", "request_queue").get("params", {})
	_check(int(request_params.get("damage_per_request", 0)) > 0, "request queue config has damage per request")
	_check(config.get_def("statuses", "sharding").get("timing_hooks", []).has("add_cache"), "sharding declares cache gain hook")
	var sharding_status_params: Dictionary = config.get_def("statuses", "sharding").get("params", {})
	_check(int(sharding_status_params.get("extra_cache_amount", 0)) > 0, "sharding config has extra cache amount")
	_check(config.get_def("statuses", "state_boost").get("timing_hooks", []).has("card_played"), "state boost declares card played hook")
	var state_boost_params: Dictionary = config.get_def("statuses", "state_boost").get("params", {})
	_check(int(state_boost_params.get("trigger_play_count", 0)) == 4, "state boost config has fourth-card trigger")
	_check(int(state_boost_params.get("style_layer_amount", 0)) > 0, "state boost config grants style layer")
	_check(config.get_def("statuses", "hotfix_style").get("timing_hooks", []).has("deal_damage"), "hotfix style declares damage hook")
	_check(config.get_def("statuses", "vue_suite").get("timing_hooks", []).has("round_start"), "vue suite declares round start hook")
	var vue_params: Dictionary = config.get_def("statuses", "vue_suite").get("params", {})
	_check(int(vue_params.get("component_amount", 0)) > 0, "vue suite config has component amount")
	_check(config.get_def("statuses", "bug").get("timing_hooks", []).has("deal_damage"), "bug declares damage hook")
	_check(config.get_def("statuses", "diff").get("timing_hooks", []).has("inject_bug"), "diff declares bug injection hook")
	_check(config.get_def("statuses", "diff").get("timing_hooks", []).has("deal_damage"), "diff declares damage hook")
	_check(config.get_def("statuses", "auto_regression").get("timing_hooks", []).has("round_end"), "auto regression declares round end hook")
	var auto_regression_params: Dictionary = config.get_def("statuses", "auto_regression").get("params", {})
	_check(int(auto_regression_params.get("trigger_damage", 0)) > 0, "auto regression config has trigger damage")
	_check(int(auto_regression_params.get("case_amount", 0)) > 0, "auto regression config has case amount")
	_check(config.get_def("statuses", "case_matrix").get("timing_hooks", []).has("add_case"), "case matrix declares add case hook")
	var case_matrix_params: Dictionary = config.get_def("statuses", "case_matrix").get("params", {})
	_check(int(case_matrix_params.get("case_amount", 0)) > 0, "case matrix config has case amount")
	_check(config.get_def("statuses", "cache").get("timing_hooks", []).has("deal_damage"), "cache declares damage hook")
	_check(config.get_def("statuses", "compute").get("timing_hooks", []).has("deal_damage"), "compute declares damage hook")
	_check(config.get_def("statuses", "complexity").get("timing_hooks", []).has("add_compute"), "complexity declares compute gain hook")
	_check(config.get_def("statuses", "complexity").get("timing_hooks", []).has("round_start"), "complexity declares round start pressure hook")
	var complexity_params: Dictionary = config.get_def("statuses", "complexity").get("params", {})
	_check(int(complexity_params.get("compute_complexity_gain", 0)) > 0, "complexity config gains from compute")
	_check(int(complexity_params.get("pressure_threshold", 0)) > 0, "complexity config has pressure threshold")
	var linear_probe_entries: Array = content.effect_entries(content.card_def("card_algo_linear_probe").get("effect_group_id", ""))
	var linear_probe_damages := false
	var linear_probe_adds_compute := false
	for entry in linear_probe_entries:
		if entry.get("effect_type", "") == "deal_damage" and int(entry.get("params", {}).get("amount", 0)) > 0:
			linear_probe_damages = true
		if entry.get("effect_type", "") == "add_compute" and int(entry.get("params", {}).get("amount", 0)) > 0:
			linear_probe_adds_compute = true
	_check(linear_probe_damages, "algorithm linear probe deals damage")
	_check(linear_probe_adds_compute, "algorithm linear probe adds compute")
	var starter_compress_entries: Array = content.effect_entries(content.card_def("card_algo_complexity_compress").get("effect_group_id", ""))
	var starter_compress_blocks := false
	var starter_compress_reduces := false
	for entry in starter_compress_entries:
		if entry.get("effect_type", "") == "gain_block" and int(entry.get("params", {}).get("amount", 0)) > 0:
			starter_compress_blocks = true
		if entry.get("effect_type", "") == "modify_complexity" and int(entry.get("params", {}).get("amount", 0)) < 0:
			starter_compress_reduces = true
	_check(starter_compress_blocks, "algorithm starter complexity compress grants block")
	_check(starter_compress_reduces, "algorithm starter complexity compress lowers complexity")
	var heuristic_entries: Array = content.effect_entries(content.card_def("card_algo_heuristic_search").get("effect_group_id", ""))
	var heuristic_draws := false
	var heuristic_adds_compute := false
	var heuristic_blocks := false
	for entry in heuristic_entries:
		if entry.get("effect_type", "") == "draw_cards":
			heuristic_draws = true
		if entry.get("effect_type", "") == "add_compute" and int(entry.get("params", {}).get("amount", 0)) > 0:
			heuristic_adds_compute = true
		if entry.get("effect_type", "") == "gain_block":
			heuristic_blocks = true
	_check(heuristic_draws, "algorithm heuristic search draws")
	_check(heuristic_adds_compute, "algorithm heuristic search adds compute")
	_check(not heuristic_blocks, "algorithm heuristic search does not use generic block")
	var local_opt_entries: Array = content.effect_entries(content.card_def("card_algo_local_opt").get("effect_group_id", ""))
	var local_opt_reduces := false
	var local_opt_discounts := false
	for entry in local_opt_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "modify_complexity" and int(params.get("amount", 0)) < 0:
			local_opt_reduces = true
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "cost_reduction":
			local_opt_discounts = true
	_check(local_opt_reduces, "algorithm local optimum lowers complexity")
	_check(local_opt_discounts, "algorithm local optimum discounts next card")
	_check(config.get_def("statuses", "dynamic_programming").get("timing_hooks", []).has("card_played"), "dynamic programming declares card played hook")
	var dynamic_params: Dictionary = config.get_def("statuses", "dynamic_programming").get("params", {})
	_check(int(dynamic_params.get("compute_amount", 0)) > 0, "dynamic programming config has compute amount")
	_check(int(dynamic_params.get("draw_amount", 0)) > 0, "dynamic programming config has draw amount")
	var dynamic_entries: Array = content.effect_entries(content.card_def("card_algo_dynamic_programming").get("effect_group_id", ""))
	var dynamic_applies_status := false
	var dynamic_generic_draw := false
	for entry in dynamic_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and entry.get("target_type", "") == "self" and params.get("status_id", "") == "dynamic_programming":
			dynamic_applies_status = true
		if entry.get("effect_type", "") == "draw_cards":
			dynamic_generic_draw = true
	_check(dynamic_applies_status, "algorithm dynamic programming applies status")
	_check(not dynamic_generic_draw, "algorithm dynamic programming is not generic draw")
	var complexity_burst_entries: Array = content.effect_entries(content.card_def("card_algo_complexity_burst").get("effect_group_id", ""))
	var complexity_burst_scales := false
	for entry in complexity_burst_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("complexity_multiplier", 0)) > 0:
			complexity_burst_scales = true
	_check(complexity_burst_scales, "algorithm complexity burst scales with complexity")
	var big_o_entries: Array = content.effect_entries(content.card_def("card_algo_big_o_compress").get("effect_group_id", ""))
	var big_o_compresses := false
	for entry in big_o_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "compress_complexity" and int(params.get("amount", 0)) > 0 and int(params.get("compute_per_complexity", 0)) > 0 and int(params.get("block_per_complexity", 0)) > 0:
			big_o_compresses = true
	_check(big_o_compresses, "algorithm big O compress converts complexity")
	var pruning_entries: Array = content.effect_entries(content.card_def("card_algo_pruning").get("effect_group_id", ""))
	var pruning_reduces_complexity := false
	var pruning_discounts_next_card := false
	for entry in pruning_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "modify_complexity" and int(params.get("amount", 0)) < 0:
			pruning_reduces_complexity = true
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "cost_reduction" and int(params.get("amount", 0)) > 0:
			pruning_discounts_next_card = true
	_check(pruning_reduces_complexity, "algorithm pruning lowers complexity")
	_check(pruning_discounts_next_card, "algorithm pruning discounts next card")
	var monte_entries: Array = content.effect_entries(content.card_def("card_algo_monte_carlo").get("effect_group_id", ""))
	var monte_creates_random := false
	var monte_draws := false
	var monte_blocks := false
	var monte_reduces_complexity := false
	for entry in monte_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "create_random_card" and String(params.get("card_id", "")).contains("card_algo_greedy_sample") and params.get("destination", "") == "hand":
			monte_creates_random = true
		if entry.get("effect_type", "") == "draw_cards" and int(params.get("amount", 0)) > 0:
			monte_draws = true
		if entry.get("effect_type", "") == "gain_block":
			monte_blocks = true
		if entry.get("effect_type", "") == "modify_complexity" and int(params.get("amount", 0)) < 0:
			monte_reduces_complexity = true
	_check(monte_creates_random, "algorithm monte carlo creates a random scheme card")
	_check(monte_draws, "algorithm monte carlo draws")
	_check(not monte_blocks, "algorithm monte carlo does not grant generic block")
	_check(not monte_reduces_complexity, "algorithm monte carlo does not use generic complexity reduction")
	var astar_entries: Array = content.effect_entries(content.card_def("card_algo_astar").get("effect_group_id", ""))
	var astar_fetches_key := false
	var astar_blocks := false
	var astar_adds_compute := false
	for entry in astar_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "fetch_key_card" and String(params.get("card_id", "")).contains("card_algo_matrix_mul") and String(params.get("next_card_id", "")).contains("card_algo_pruning"):
			astar_fetches_key = true
		if entry.get("effect_type", "") == "gain_block":
			astar_blocks = true
		if entry.get("effect_type", "") == "add_compute":
			astar_adds_compute = true
	_check(astar_fetches_key, "algorithm astar fetches key cards and sets next draw candidates")
	_check(not astar_blocks, "algorithm astar does not grant generic block")
	_check(not astar_adds_compute, "algorithm astar does not add generic compute")
	var matrix_entries: Array = content.effect_entries(content.card_def("card_algo_matrix_mul").get("effect_group_id", ""))
	var matrix_has_threshold_payoff := false
	var matrix_adds_compute := false
	for entry in matrix_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("compute_threshold", 0)) > 0 and int(params.get("compute_threshold_bonus", 0)) > 0:
			matrix_has_threshold_payoff = true
		if entry.get("effect_type", "") == "add_compute":
			matrix_adds_compute = true
	_check(matrix_has_threshold_payoff, "algorithm matrix multiplication has compute threshold payoff")
	_check(not matrix_adds_compute, "algorithm matrix multiplication does not add generic compute")
	_check(config.get_def("statuses", "requirement_change").get("timing_hooks", []).has("enemy_before_action"), "requirement change declares enemy action hook")
	var requirement_params: Dictionary = config.get_def("statuses", "requirement_change").get("params", {})
	_check(int(requirement_params.get("intent_amount_reduction", 0)) > 0, "requirement change config reduces intent amount")
	_check(int(requirement_params.get("consume_per_action", 0)) > 0, "requirement change config consumes stacks")
	_check(config.get_def("statuses", "meeting_minutes_boost").get("timing_hooks", []).has("apply_status"), "meeting minutes boost declares status hook")
	_check(config.get_def("statuses", "meeting_minutes_boost").get("timing_hooks", []).has("modify_intent"), "meeting minutes boost declares intent hook")
	_check(bool(config.get_def("statuses", "meeting_minutes_boost").get("is_hidden", false)), "meeting minutes boost is hidden")
	var meeting_minutes_params: Dictionary = config.get_def("statuses", "meeting_minutes_boost").get("params", {})
	_check(int(meeting_minutes_params.get("requirement_change_bonus", 0)) > 0, "meeting minutes boost config has requirement bonus")
	_check(int(meeting_minutes_params.get("intent_reduction_bonus", 0)) > 0, "meeting minutes boost config has intent bonus")
	_check(config.get_def("statuses", "pm_review").get("timing_hooks", []).has("modify_intent"), "pm review declares intent hook")
	_check(config.get_def("statuses", "pm_review").get("timing_hooks", []).has("round_start"), "pm review declares round reset hook")
	var pm_review_params: Dictionary = config.get_def("statuses", "pm_review").get("params", {})
	_check(int(pm_review_params.get("block_amount", 0)) > 0, "pm review config has block amount")
	_check(int(pm_review_params.get("draw_amount", 0)) > 0, "pm review config has draw amount")
	_check(config.get_def("statuses", "scope_spread").get("timing_hooks", []).has("apply_status"), "scope spread declares status hook")
	var scope_params: Dictionary = config.get_def("statuses", "scope_spread").get("params", {})
	_check(int(scope_params.get("spread_amount", 0)) > 0, "scope spread config has spread amount")
	var scope_entries: Array = content.effect_entries(content.card_def("card_pm_scope_spread").get("effect_group_id", ""))
	var scope_spread_applies_status := false
	for entry in scope_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "scope_spread":
			scope_spread_applies_status = true
	_check(scope_spread_applies_status, "pm scope spread applies scope spread status")
	_check(config.get_def("statuses", "service_online").get("timing_hooks", []).has("round_end"), "service online declares round end hook")
	var flush_entries: Array = content.effect_entries(content.card_def("card_backend_flush_all").get("effect_group_id", ""))
	var flush_consumes_cache := false
	for entry in flush_entries:
		var params: Dictionary = entry.get("params", {})
		if bool(params.get("consume_cache", false)) and int(params.get("cache_multiplier", 0)) >= 3:
			flush_consumes_cache = true
	_check(flush_consumes_cache, "backend flush all consumes cache")
	var report_entries: Array = content.effect_entries(content.card_def("card_tester_report_lock").get("effect_group_id", ""))
	var report_lock_scales_status := false
	for entry in report_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and int(params.get("bug_multiplier", 0)) >= 2 and int(params.get("case_multiplier", 0)) >= 2 and int(params.get("diff_multiplier", 0)) >= 3:
			report_lock_scales_status = true
	_check(report_lock_scales_status, "tester report lock scales target statuses")
	_check(content.card_def("card_tester_92_bugs").get("target_type", "") == "selected", "tester fatal bug submission targets selected enemy")
	var fatal_bug_entries: Array = content.effect_entries(content.card_def("card_tester_92_bugs").get("effect_group_id", ""))
	var fatal_bug_has_hits := false
	for entry in fatal_bug_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "inject_bug" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0 and int(params.get("hits", 0)) >= 4:
			fatal_bug_has_hits = true
	_check(fatal_bug_has_hits, "tester fatal bug submission injects multiple bug hits")
	var auto_regression_entries: Array = content.effect_entries(content.card_def("card_tester_auto_regression").get("effect_group_id", ""))
	var auto_regression_applies_status := false
	for entry in auto_regression_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "auto_regression":
			auto_regression_applies_status = true
	_check(auto_regression_applies_status, "tester auto regression applies auto regression status")
	_check(content.card_def("card_tester_repro_steps").get("target_type", "") == "selected", "tester repro steps targets selected enemy")
	var repro_steps_entries: Array = content.effect_entries(content.card_def("card_tester_repro_steps").get("effect_group_id", ""))
	var repro_steps_injects_bug := false
	for entry in repro_steps_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "inject_bug" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0:
			repro_steps_injects_bug = true
	_check(repro_steps_injects_bug, "tester repro steps injects bug")
	_check(content.card_def("card_tester_boundary_check").get("target_type", "") == "selected", "tester boundary check targets selected enemy")
	var boundary_check_entries: Array = content.effect_entries(content.card_def("card_tester_boundary_check").get("effect_group_id", ""))
	var boundary_check_has_params := false
	for entry in boundary_check_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "boundary_check" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0 and int(params.get("bonus_amount", 0)) > 0 and int(params.get("low_hp_percent", 0)) == 50 and int(params.get("high_attack_threshold", 0)) == 10:
			boundary_check_has_params = true
	_check(boundary_check_has_params, "tester boundary check has selected target thresholds")
	_check(content.card_def("card_tester_bug_upgrade").get("target_type", "") == "selected", "tester bug upgrade targets selected enemy")
	var bug_upgrade_entries: Array = content.effect_entries(content.card_def("card_tester_bug_upgrade").get("effect_group_id", ""))
	var bug_upgrade_upgrades_bug := false
	for entry in bug_upgrade_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "upgrade_bug" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0:
			bug_upgrade_upgrades_bug = true
	_check(bug_upgrade_upgrades_bug, "tester bug upgrade upgrades existing bug")
	_check(content.card_def("card_tester_regression_confirm").get("target_type", "") == "selected", "tester regression confirm targets selected enemy")
	var regression_confirm_entries: Array = content.effect_entries(content.card_def("card_tester_regression_confirm").get("effect_group_id", ""))
	var regression_confirm_checks_case := false
	for entry in regression_confirm_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "confirm_regression" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > 0 and int(params.get("draw_amount", 0)) > 0:
			regression_confirm_checks_case = true
	_check(regression_confirm_checks_case, "tester regression confirm checks cases before diff")
	var case_matrix_entries: Array = content.effect_entries(content.card_def("card_tester_case_matrix").get("effect_group_id", ""))
	var case_matrix_applies_status := false
	for entry in case_matrix_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "case_matrix":
			case_matrix_applies_status = true
	_check(case_matrix_applies_status, "tester case matrix applies case matrix status")
	_check(content.card_def("card_pm_change_wording").get("target_type", "") == "selected", "pm change wording targets selected enemy")
	var change_wording_entries: Array = content.effect_entries(content.card_def("card_pm_change_wording").get("effect_group_id", ""))
	var change_wording_lowers_intent := false
	var change_wording_blocks := false
	for entry in change_wording_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "modify_intent" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) < 0:
			change_wording_lowers_intent = true
		if entry.get("effect_type", "") == "gain_block":
			change_wording_blocks = true
	_check(change_wording_lowers_intent, "pm change wording lowers selected intent")
	_check(not change_wording_blocks, "pm change wording does not use generic block")
	_check(content.card_def("card_pm_meeting_minutes").get("target_type", "") == "self", "pm meeting minutes targets self")
	var meeting_minutes_entries: Array = content.effect_entries(content.card_def("card_pm_meeting_minutes").get("effect_group_id", ""))
	var meeting_minutes_draws := false
	var meeting_minutes_applies_boost := false
	var meeting_minutes_blocks := false
	for entry in meeting_minutes_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "draw_cards" and int(params.get("amount", 0)) > 0:
			meeting_minutes_draws = true
		if entry.get("effect_type", "") == "apply_status" and entry.get("target_type", "") == "self" and params.get("status_id", "") == "meeting_minutes_boost":
			meeting_minutes_applies_boost = true
		if entry.get("effect_type", "") == "gain_block":
			meeting_minutes_blocks = true
	_check(meeting_minutes_draws, "pm meeting minutes draws")
	_check(meeting_minutes_applies_boost, "pm meeting minutes stores control boost")
	_check(not meeting_minutes_blocks, "pm meeting minutes does not use generic block")
	_check(content.card_def("card_pm_revision_notice").get("target_type", "") == "selected", "pm revision notice targets selected enemy")
	var revision_notice_entries: Array = content.effect_entries(content.card_def("card_pm_revision_notice").get("effect_group_id", ""))
	var revision_notice_applies_requirement := false
	var revision_notice_blocks := false
	for entry in revision_notice_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and entry.get("target_type", "") == "selected" and params.get("status_id", "") == "requirement_change":
			revision_notice_applies_requirement = true
		if entry.get("effect_type", "") == "gain_block":
			revision_notice_blocks = true
	_check(revision_notice_applies_requirement, "pm revision notice applies requirement change")
	_check(not revision_notice_blocks, "pm revision notice does not use generic block")
	_check(content.card_def("card_pm_review").get("target_type", "") == "self", "pm review targets self")
	var pm_review_entries: Array = content.effect_entries(content.card_def("card_pm_review").get("effect_group_id", ""))
	var pm_review_applies_status := false
	var pm_review_generic_blocks := false
	for entry in pm_review_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "apply_status" and entry.get("target_type", "") == "self" and params.get("status_id", "") == "pm_review":
			pm_review_applies_status = true
		if entry.get("effect_type", "") == "gain_block":
			pm_review_generic_blocks = true
	_check(pm_review_applies_status, "pm review applies review status")
	_check(not pm_review_generic_blocks, "pm review is not generic block")
	_check(content.card_def("card_pm_delay_meeting").get("target_type", "") == "selected", "pm delay meeting targets selected enemy")
	var delay_meeting_entries: Array = content.effect_entries(content.card_def("card_pm_delay_meeting").get("effect_group_id", ""))
	var delay_meeting_delays := false
	var delay_meeting_blocks := false
	for entry in delay_meeting_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "delay_intent" and entry.get("target_type", "") == "selected" and int(params.get("high_attack_threshold", 0)) > 0:
			delay_meeting_delays = true
		if entry.get("effect_type", "") == "gain_block":
			delay_meeting_blocks = true
	_check(delay_meeting_delays, "pm delay meeting delays high pressure intent")
	_check(not delay_meeting_blocks, "pm delay meeting does not use generic block")
	_check(content.card_def("card_pm_milestone_split").get("target_type", "") == "selected", "pm milestone split targets selected enemy")
	var milestone_split_entries: Array = content.effect_entries(content.card_def("card_pm_milestone_split").get("effect_group_id", ""))
	var milestone_split_splits := false
	var milestone_split_blocks := false
	for entry in milestone_split_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "split_intent" and entry.get("target_type", "") == "selected" and int(params.get("hits", 0)) > 1:
			milestone_split_splits = true
		if entry.get("effect_type", "") == "gain_block":
			milestone_split_blocks = true
	_check(milestone_split_splits, "pm milestone split breaks high pressure intent into hits")
	_check(not milestone_split_blocks, "pm milestone split does not use generic block")
	_check(content.card_def("card_pm_schedule_compress").get("target_type", "") == "highest_priority_enemy", "pm schedule compress targets priority")
	_check(content.card_def("card_pm_roadmap").get("target_type", "") == "highest_priority_enemy", "pm roadmap targets priority")
	var roadmap_entries: Array = content.effect_entries(content.card_def("card_pm_roadmap").get("effect_group_id", ""))
	var roadmap_scales_requirement := false
	var roadmap_adds_requirement := false
	for entry in roadmap_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "deal_damage" and entry.get("target_type", "") == "highest_priority_enemy" and int(params.get("requirement_change_multiplier", 0)) > 0:
			roadmap_scales_requirement = true
		if entry.get("effect_type", "") == "apply_status" and params.get("status_id", "") == "requirement_change":
			roadmap_adds_requirement = true
	_check(roadmap_scales_requirement, "pm roadmap scales damage from requirement change")
	_check(not roadmap_adds_requirement, "pm roadmap is a payoff rather than another generic mark")
	_check(content.card_def("card_pm_align_all").get("target_type", "") == "self", "pm align all is non-targeted")
	var align_all_entries: Array = content.effect_entries(content.card_def("card_pm_align_all").get("effect_group_id", ""))
	var align_all_rerolls := false
	var align_all_blocks := false
	for entry in align_all_entries:
		if entry.get("effect_type", "") == "reroll_intent" and entry.get("target_type", "") == "all_enemies":
			align_all_rerolls = true
		if entry.get("effect_type", "") == "gain_block":
			align_all_blocks = true
	_check(align_all_rerolls, "pm align all rerolls every enemy intent")
	_check(not align_all_blocks, "pm align all does not use generic block")
	_check(content.card_def("card_pm_priority_shuffle").get("target_type", "") == "selected", "pm priority shuffle targets selected enemy")
	var priority_shuffle_entries: Array = content.effect_entries(content.card_def("card_pm_priority_shuffle").get("effect_group_id", ""))
	var priority_shuffle_blocks := false
	var priority_shuffle_reorders := false
	for entry in priority_shuffle_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "gain_block" and int(params.get("amount", 0)) > 0:
			priority_shuffle_blocks = true
		if entry.get("effect_type", "") == "shuffle_priority" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) > int(params.get("bonus_amount", 0)):
			priority_shuffle_reorders = true
	_check(priority_shuffle_blocks, "pm priority shuffle grants block")
	_check(priority_shuffle_reorders, "pm priority shuffle assigns selected target highest priority")
	_check(content.card_def("card_pm_priority_top").get("target_type", "") == "selected", "pm priority top targets selected enemy")
	var priority_top_entries: Array = content.effect_entries(content.card_def("card_pm_priority_top").get("effect_group_id", ""))
	var priority_top_sets_target := false
	var priority_top_draws := false
	for entry in priority_top_entries:
		var params: Dictionary = entry.get("params", {})
		if entry.get("effect_type", "") == "set_priority_top" and entry.get("target_type", "") == "selected" and int(params.get("amount", 0)) >= 5 and bool(params.get("clear_other_priority", false)):
			priority_top_sets_target = true
		if entry.get("effect_type", "") == "draw_cards" and int(params.get("amount", 0)) > 0:
			priority_top_draws = true
	_check(priority_top_sets_target, "pm priority top sets a clear highest priority")
	_check(priority_top_draws, "pm priority top preserves tempo with draw")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_salesman"), "pollute"), "salesman has pollute intent")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_workaholic_coworker"), "multi_attack"), "workaholic has multi attack intent")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_meeting_maniac"), "spawn"), "meeting maniac has spawn intent")
	_check(_has_intent_type(content.intent_entries_for_enemy("enemy_compliance_judge"), "cleanse_player"), "compliance judge has cleanse intent")
	_check(content.phase_entries_for_enemy("boss_pitch_supervisor").size() >= 2, "pitch supervisor phase group resolves")
	_check(content.phase_entries_for_enemy("boss_mutant_ceo").size() >= 3, "ceo boss phase group resolves")
	_check(content.phase_entries_for_enemy("elite_outsource_manager").size() >= 1, "elite phase group resolves")

func _validate_run_class_locks(config, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var backend_run: Dictionary = run_session.create_new_run("backend")
	_check(not backend_run.is_empty(), "run session creates backend public run")
	for class_id in ["frontend", "tester", "algorithm", "product_manager", "hr"]:
		var locked_run: Dictionary = run_session.create_new_run(class_id)
		_check(locked_run.is_empty(), "%s public run creation is locked" % class_id)
		_check(String(run_session.run_state.get("selected_class_id", "")) == "backend", "%s locked creation preserves active run" % class_id)
		var internal_run: Dictionary = run_session.create_new_run(class_id, true)
		_check(not internal_run.is_empty(), "%s internal coverage run can still be created" % class_id)
		_check(String(run_session.run_state.get("selected_class_id", "")) == class_id, "%s internal run updates active run" % class_id)
		run_session.create_new_run("backend")

func _validate_run_reset_cleanup() -> void:
	var battle = BattleServiceScript.new()
	battle.battle_state = { "phase": "player", "log": ["leftover_battle_state"] }
	battle.clear()
	_check(battle.battle_state.is_empty(), "battle service clear removes active battle state")
	var app_root_source := FileAccess.get_file_as_string("res://Scripts/Autoload/AppRoot.gd")
	_check(app_root_source.contains("battle_service.clear()"), "app root reset clears battle service state")

func _validate_class_resources(class_id: String) -> void:
	var battle = BattleServiceScript.new()
	var resources = battle.call("_initial_class_resources", class_id)
	_check(resources.size() > 0, "%s class resources initialized" % class_id)

func _validate_battle(class_id: String, config, content, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run(class_id)
	var first_node_id := String(run.get("map_state", {}).get("available_next_nodes", [])[0])
	var node: Dictionary = map.choose_node(run, first_node_id)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)
	var battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, node)
	var guard := 0
	while guard < 80 and not ["victory", "defeat"].has(battle.battle_state.get("phase", "")):
		var player: Dictionary = battle.battle_state.get("player", {})
		var played := false
		for i in range(player.get("hand", []).size()):
			if battle.can_play_card(i):
				battle.play_card(run, i, 0)
				played = true
				break
		if battle.battle_state.get("phase", "") == "victory":
			break
		if not played:
			battle.end_turn(run)
		guard += 1
	_check(battle.battle_state.get("phase", "") == "victory", "%s battle reaches victory" % class_id)
	_check(not run.get("pending_reward_state", {}).is_empty(), "%s reward generated" % class_id)
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	var reward: Dictionary = run.get("pending_reward_state", {})
	var chosen_card := String(reward.get("candidate_card_ids", [""])[0])
	var result: String = reward_service.accept_battle_reward(run, chosen_card)
	_check(result == "map", "%s reward returns to map" % class_id)
	_check(run.get("pending_reward_state", {}).is_empty(), "%s reward cleared" % class_id)
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "%s reward card added" % class_id)
	_check(int(run.get("currency_perf_points", 0)) > 0, "%s reward currency added" % class_id)
	_check(String(run.get("current_node_id", "")) == "", "%s completed node is cleared after reward" % class_id)

func _validate_combat_mechanics(config, content, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)

	var run := run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	var battle = _start_first_battle(run, content, map, executor)
	_check(int(battle.battle_state.get("player", {}).get("hand", []).size()) == 6, "blue light glasses opening draw")

	var player: Dictionary = battle.battle_state.get("player", {})
	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_lumbar_cushion")
	run["owned_relic_ids"].append("relic_hair_shampoo")
	var base_max_spirit := int(run.get("player_state", {}).get("max_spirit", 0))
	var base_current_spirit := int(run.get("player_state", {}).get("current_spirit", 0))
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	_check(int(player.get("max_spirit", 0)) == base_max_spirit + 6, "hair shampoo increases max spirit")
	_check(int(player.get("current_spirit", 0)) == base_current_spirit + 6, "hair shampoo increases current spirit")
	_check(int(player.get("current_block", 0)) >= 4, "lumbar cushion grants opening block")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_api_gateway"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("api_gateway", 0)) == 1, "backend api gateway status is applied")
	player["hand"] = []
	player["draw_pile"] = ["card_backend_interface_probe"]
	player["discard_pile"] = []
	player["class_resource_state"] = { "services": 0, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_block", 0)) == 4, "backend api gateway grants block on round start")
	_check(not player.get("hand", []).has("card_backend_interface_probe"), "backend api gateway needs services to draw")
	player["hand"] = []
	player["draw_pile"] = ["card_backend_interface_probe"]
	player["discard_pile"] = []
	player["class_resource_state"] = { "services": 2, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(player.get("hand", []).has("card_backend_interface_probe"), "backend api gateway draws with enough services")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_coffee_boost", "card_shared_coffee_boost", "card_shared_coffee_boost"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 0
	for _i in range(3):
		battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) >= 1, "frontend design link grants style layer on third card")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var pixel_tap_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	pixel_tap_enemy["current_hp"] = 50
	pixel_tap_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_pixel_tap"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["cards_played_this_turn"] = 0
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(pixel_tap_enemy.get("current_hp", 0)) == 40, "frontend pixel tap deals base damage as first card")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	pixel_tap_enemy = battle.battle_state.get("enemies", [])[0]
	pixel_tap_enemy["current_hp"] = 50
	pixel_tap_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_pixel_tap"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["cards_played_this_turn"] = 1
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(pixel_tap_enemy.get("current_hp", 0)) == 37, "frontend pixel tap adds light damage after another card")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"].append("relic_figma_library")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	executor.execute([{ "effect_type": "add_component", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var components_after_first := int(player.get("class_resource_state", {}).get("components", 0))
	executor.execute([{ "effect_type": "add_component", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(components_after_first == 2, "figma library duplicates first component")
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 3, "figma library triggers only once")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_component_reuse"]
	player["draw_pile"] = ["card_frontend_pixel_tap"]
	player["current_energy"] = 3
	player["class_resource_state"]["components"] = 2
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 3, "frontend component reuse copies existing component")
	_check(player.get("hand", []).has("card_frontend_pixel_tap"), "frontend component reuse draws after copy")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_component_reuse"]
	player["draw_pile"] = ["card_frontend_pixel_tap"]
	player["current_energy"] = 3
	player["class_resource_state"]["components"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 0, "frontend component reuse needs an existing component")
	_check(not player.get("hand", []).has("card_frontend_pixel_tap"), "frontend component reuse does not draw without copy")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_flex_layout"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["components"] = 0
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) == 8, "frontend flex layout grants configured block")
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 1, "frontend flex layout creates a component")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend flex layout does not create style layers")
	_check(int(player.get("current_energy", 0)) == 2, "frontend flex layout charges card cost")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_slice_sprint"]
	player["draw_pile"] = ["card_frontend_pixel_tap"]
	player["discard_pile"] = []
	player["current_energy"] = 0
	player["current_block"] = 0
	player["class_resource_state"]["components"] = 0
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(player.get("hand", []).has("card_frontend_pixel_tap"), "frontend slice sprint draws a card")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 1, "frontend slice sprint creates a style layer")
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 0, "frontend slice sprint does not create components")
	_check(int(player.get("current_block", 0)) == 0, "frontend slice sprint does not grant block")
	_check(int(player.get("current_energy", 0)) == 0, "frontend slice sprint stays zero cost")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var hotfix_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	hotfix_enemy["current_hp"] = 50
	hotfix_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_hotfix_style"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("hotfix_style", 0)) == 1, "frontend hotfix style stores next attack amplifier")
	_check(int(player.get("current_block", 0)) == 0, "frontend hotfix style does not grant block")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend hotfix style does not create immediate style layer")
	_check(int(player.get("current_energy", 0)) == 2, "frontend hotfix style charges card cost")
	player["hand"] = ["card_frontend_pixel_tap"]
	battle.play_card(run, 0, 0)
	_check(int(hotfix_enemy.get("current_hp", 0)) == 36, "frontend hotfix style amplifies next attack")
	_check(int(player.get("status_list", {}).get("hotfix_style", 0)) == 0, "frontend hotfix style is consumed by attack")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend hotfix style uses virtual style layer")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_hotfix_style"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	battle.call("_tick_player_turn_end_statuses", player)
	_check(int(player.get("status_list", {}).get("hotfix_style", 0)) == 0, "frontend hotfix style expires at turn end")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_pixel_align"]
	player["draw_pile"] = ["card_frontend_pixel_tap"]
	player["discard_pile"] = []
	player["current_energy"] = 0
	player["current_block"] = 0
	player["class_resource_state"]["components"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) == 4, "frontend pixel align grants base block without component")
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 0, "frontend pixel align does not generate components")
	_check(not player.get("hand", []).has("card_frontend_pixel_tap"), "frontend pixel align does not draw")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_pixel_align"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 0
	player["current_block"] = 0
	player["class_resource_state"]["components"] = 2
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) == 9, "frontend pixel align gains bonus block with component")
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 2, "frontend pixel align keeps existing components")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var compat_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	compat_enemy["current_hp"] = 50
	compat_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_compat_patch"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["class_resource_state"]["style_layers"] = 2
	player["status_list"] = { "anxiety": 1 }
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("anxiety", 0)) == 0, "frontend compatibility patch cleanses one debuff")
	_check(int(player.get("status_list", {}).get("compatibility_patch", 0)) == 1, "frontend compatibility patch status is applied")
	player["hand"] = ["card_shared_keyboard_smash"]
	player["current_energy"] = 2
	battle.play_card(run, 0, 0)
	_check(int(compat_enemy.get("current_hp", 0)) == 38, "frontend compatibility patch still allows style bonus damage")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 2, "frontend compatibility patch prevents style layer consumption")
	battle.call("_tick_player_turn_end_statuses", player)
	_check(int(player.get("status_list", {}).get("compatibility_patch", 0)) == 0, "frontend compatibility patch expires at turn end")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var state_boost_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	state_boost_enemy["current_hp"] = 50
	state_boost_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_pixel_tap"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["cards_played_this_turn"] = 3
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = { "state_boost": 1 }
	battle.play_card(run, 0, 0)
	_check(int(state_boost_enemy.get("current_hp", 0)) == 36, "frontend state boost buffs the fourth card")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend state boost style layer is consumed by attack")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_vue_suite"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["class_resource_state"]["components"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("vue_suite", 0)) == 1, "frontend vue suite status is applied")
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("components", 0)) == 1, "frontend vue suite creates a component on round start")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var motion_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	motion_enemy["current_hp"] = 50
	motion_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_motion_overload"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["cards_played_this_turn"] = 3
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(motion_enemy.get("current_hp", 0)) == 32, "frontend motion overload uses current turn play count")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var first_screen_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	first_screen_enemy["current_hp"] = 100
	first_screen_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_first_screen"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("first_screen_optimization", 0)) == 2, "frontend first screen stores two discounts")
	_check(int(player.get("current_energy", 0)) == 2, "frontend first screen charges its own cost")
	player["hand"] = ["card_shared_keyboard_smash", "card_frontend_flex_layout", "card_shared_rollback"]
	_check(battle.hand_card_cost(0) == 0, "frontend first screen previews first discount")
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 2, "frontend first screen discounts first following card")
	_check(int(player.get("status_list", {}).get("first_screen_optimization", 0)) == 1, "frontend first screen consumes one discount per card")
	_check(battle.hand_card_cost(0) == 0, "frontend first screen previews second discount")
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 2, "frontend first screen discounts second following card")
	_check(int(player.get("status_list", {}).get("first_screen_optimization", 0)) == 0, "frontend first screen consumes both discounts")
	_check(battle.hand_card_cost(0) == 1, "frontend first screen does not discount third following card")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_frontend_first_screen"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	player["hand"] = []
	player["draw_pile"] = []
	player["discard_pile"] = []
	battle.end_turn(run)
	_check(int(player.get("status_list", {}).get("first_screen_optimization", 0)) == 0, "frontend first screen expires at turn end")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var crash_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	crash_enemy["current_hp"] = 60
	crash_enemy["current_block"] = 0
	player["hand"] = ["card_frontend_crash_animation"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["class_resource_state"]["style_layers"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(crash_enemy.get("current_hp", 0)) == 35, "frontend crash animation converts style layers into extra hits")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 0, "frontend crash animation consumes all style layers")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = ["relic_gantt_roadmap"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = []
	player["draw_pile"] = ["card_pm_schedule_compress", "card_pm_priority_shuffle"]
	var gantt_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	gantt_enemy["intent"] = { "intent_type": "attack", "amount": 9 }
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var gantt_hand_after_first := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(gantt_hand_after_first == 1, "gantt roadmap draws on first intent change")
	_check(int(player.get("hand", []).size()) == 1, "gantt roadmap triggers only once")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = ["relic_pm_meeting_room_claim"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var claim_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	claim_enemy["status_list"] = {}
	player["class_resource_state"]["requirement_change_marks"] = 0
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(claim_enemy.get("status_list", {}).get("requirement_change", 0)) == 2, "meeting room claim strengthens first requirement change")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) == 2, "meeting room claim syncs boosted requirement resource")
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(claim_enemy.get("status_list", {}).get("requirement_change", 0)) == 3, "meeting room claim triggers only once per turn")
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["hand"] = []
	battle.call("_start_player_turn", run, false)
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(claim_enemy.get("status_list", {}).get("requirement_change", 0)) == 5, "meeting room claim resets on next turn")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = ["relic_paper_citation"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["class_resource_state"]["complexity"] = 3
	var paper_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	paper_enemy["current_block"] = 0
	paper_enemy["current_hp"] = 50
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(paper_enemy.get("current_hp", 0)) == 42, "paper citation adds damage at high complexity")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 0
	executor.execute([{ "effect_type": "add_compute", "target_type": "self", "params": { "amount": 2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 2, "algorithm compute gain adds compute")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 2, "algorithm compute gain raises complexity")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"].append("relic_gpu_training_card")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	executor.execute([{ "effect_type": "add_compute", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var compute_after_gpu := int(player.get("class_resource_state", {}).get("compute", 0))
	var complexity_after_gpu := int(player.get("class_resource_state", {}).get("complexity", 0))
	executor.execute([{ "effect_type": "add_compute", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(compute_after_gpu == 2, "gpu training card adds compute on first gain")
	_check(complexity_after_gpu == 2, "gpu training card bonus compute also raises complexity")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 3, "gpu training card triggers only once")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 3, "subsequent compute raises complexity once")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_publish_script"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("services", 0)) >= 1, "backend publish script deploys service")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var circuit_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	circuit_enemy["intent"] = { "intent_type": "attack", "amount": 12 }
	player["hand"] = ["card_backend_circuit_breaker"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["services"] = 2
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) == 17, "backend circuit breaker gains service and pressure block")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "backend circuit breaker gains cache from services")
	_check(int(player.get("class_resource_state", {}).get("services", 0)) == 2, "backend circuit breaker keeps services online")
	_check(int(player.get("current_energy", 0)) == 2, "backend circuit breaker charges card cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_redis_warmup"]
	player["current_energy"] = 3
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 3, "backend redis warmup grants large cache")
	_check(int(player.get("status_list", {}).get("redis_warmup", 0)) == 1, "backend redis warmup status is pending")
	player["hand"] = ["card_backend_api_gateway"]
	player["current_energy"] = 1
	_check(not battle.can_play_card(0), "backend redis warmup does not discount same turn")
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("status_list", {}).get("redis_warmup", 0)) == 0, "backend redis warmup clears at next round start")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 1, "backend redis warmup enables next card discount")
	_check(battle.hand_card_cost(0) == 1, "backend redis warmup previews discounted cost")
	_check(battle.can_play_card(0), "backend redis warmup lets discounted card play")
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 0, "backend redis warmup charges discounted cost")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 0, "backend redis warmup discount is consumed")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	for mq_enemy in battle.battle_state.get("enemies", []):
		mq_enemy["current_hp"] = 50
		mq_enemy["current_block"] = 0
	player["hand"] = ["card_backend_message_queue"]
	player["current_energy"] = 3
	player["class_resource_state"]["requests"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("requests", 0)) == 3, "backend message queue stores request resource")
	_check(int(player.get("status_list", {}).get("request_queue", 0)) == 3, "backend message queue stores request status")
	battle.call("_round_end_triggers", run)
	var request_damage_ok := true
	for mq_enemy in battle.battle_state.get("enemies", []):
		if int(mq_enemy.get("current_hp", 0)) != 41:
			request_damage_ok = false
	_check(request_damage_ok, "backend message queue damages all enemies at round end")
	_check(int(player.get("class_resource_state", {}).get("requests", 0)) == 0, "backend message queue consumes request resource")
	_check(int(player.get("status_list", {}).get("request_queue", 0)) == 0, "backend message queue consumes request status")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_sharding"]
	player["current_energy"] = 3
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("sharding", 0)) == 1, "backend sharding status is applied")
	executor.execute([{ "effect_type": "add_cache", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "backend sharding adds extra first cache each turn")
	executor.execute([{ "effect_type": "add_cache", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 3, "backend sharding only triggers once per turn")
	player["hand"] = []
	player["draw_pile"] = []
	player["discard_pile"] = []
	battle.call("_start_player_turn", run, false)
	executor.execute([{ "effect_type": "add_cache", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 5, "backend sharding resets on next turn")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_traffic_shaping"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["damage_taken_this_turn"] = 6
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) >= 6, "backend traffic shaping grants block")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 3, "backend traffic shaping converts pressure to cache")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var degrade_enemy_a: Dictionary = battle.battle_state.get("enemies", [])[0]
	degrade_enemy_a["intent"] = { "intent_type": "attack", "amount": 10 }
	var degrade_enemy_b := {
		"enemy_def_id": "enemy_workaholic_coworker",
		"name": "多段压测同事",
		"max_hp": 30,
		"current_hp": 30,
		"current_block": 0,
		"phase_index": 0,
		"intent": { "intent_type": "multi_attack", "amount": 5, "hits": 3 },
		"status_list": {},
		"runtime_flags": {},
	}
	battle.battle_state["enemies"].append(degrade_enemy_b)
	player["hand"] = ["card_backend_service_degrade"]
	player["current_energy"] = 1
	player["current_block"] = 0
	player["class_resource_state"]["services"] = 2
	player["class_resource_state"]["cache"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(degrade_enemy_a.get("intent", {}).get("amount", 0)) == 6, "backend service degrade lowers attack intent")
	_check(int(degrade_enemy_b.get("intent", {}).get("amount", 0)) == 1, "backend service degrade lowers multi attack intent")
	_check(int(player.get("current_block", 0)) == 8, "backend service degrade gains block per existing service")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 1, "backend service degrade preserves services into cache")
	_check(int(player.get("class_resource_state", {}).get("services", 0)) == 2, "backend service degrade does not consume services")
	_check(int(player.get("current_energy", 0)) == 1, "backend service degrade remains zero cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_trace_chain"]
	player["draw_pile"] = ["card_backend_api_gateway", "card_backend_interface_probe"]
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(player.get("hand", []).has("card_backend_api_gateway"), "backend trace chain fetches service card from draw pile")
	_check(player.get("draw_pile", []).has("card_backend_interface_probe"), "backend trace chain leaves non-service draw card")
	_check(not player.get("draw_pile", []).has("card_backend_api_gateway"), "backend trace chain removes fetched service from draw pile")
	_check(int(player.get("current_energy", 0)) == 2, "backend trace chain charges card cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_trace_chain"]
	player["draw_pile"] = ["card_backend_interface_probe"]
	player["discard_pile"] = ["card_backend_sharding"]
	player["current_energy"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(not player.get("hand", []).has("card_backend_sharding"), "backend trace chain does not search discard pile")
	_check(player.get("draw_pile", []).has("card_backend_interface_probe"), "backend trace chain leaves draw pile when no service card exists")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var flush_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	flush_enemy["current_hp"] = 80
	flush_enemy["current_block"] = 0
	flush_enemy["status_list"] = {}
	player["hand"] = ["card_backend_flush_all"]
	player["current_energy"] = 3
	player["class_resource_state"]["cache"] = 4
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(flush_enemy.get("current_hp", 0)) == 54, "backend flush all spends cache for damage")
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 0, "backend flush all consumes stored cache")

	run = run_session.create_new_run("frontend", true)
	run["owned_relic_ids"].append("relic_standing_desk")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["current_block"] = 0
	executor.execute([{ "effect_type": "gain_block", "target_type": "self", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	executor.execute([{ "effect_type": "gain_block", "target_type": "self", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) == 12, "standing desk adds only first block per turn")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = []
	player["draw_pile"] = []
	player["discard_pile"] = ["card_shared_keyboard_smash", "card_shared_standup", "card_shared_meeting_mute"]
	executor.execute([{ "effect_type": "move_card", "target_type": "self", "params": { "source": "discard", "destination": "draw", "amount": 1, "card_id": "card_shared_standup" } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(not player.get("discard_pile", []).has("card_shared_standup"), "move card removes named card from source pile")
	_check(player.get("draw_pile", []).has("card_shared_standup"), "move card adds named card to destination pile")
	executor.execute([{ "effect_type": "move_card", "target_type": "self", "params": { "source": "draw", "destination": "hand", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(player.get("hand", []).has("card_shared_standup"), "move card moves top card when no card id is specified")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	var deck_before_executor_reward := int(run.get("deck_state", {}).get("master_deck", []).size())
	executor.execute([{ "effect_type": "add_random_card", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before_executor_reward + 1, "executor add random card updates run deck")
	var relic_before_executor_reward := int(run.get("owned_relic_ids", []).size())
	executor.execute([{ "effect_type": "add_random_relic", "target_type": "self", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before_executor_reward + 1, "executor add random relic updates run relics")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "executor add random relic avoids duplicates")
	executor.execute([{ "effect_type": "upgrade_card", "target_type": "self", "params": { "amount": 1, "card_id": "card_backend_interface_probe" } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(run.get("deck_state", {}).get("upgraded_cards", []).has("card_backend_interface_probe"), "executor upgrade card updates run deck")
	_check(battle.battle_state.get("upgraded_card_ids", []).has("card_backend_interface_probe"), "executor upgrade card updates active battle")
	var circuit_count_before := _count_card(run.get("deck_state", {}).get("master_deck", []), "card_backend_circuit_breaker")
	executor.execute([{ "effect_type": "remove_card", "target_type": "self", "params": { "amount": 1, "card_id": "card_backend_circuit_breaker" } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(_count_card(run.get("deck_state", {}).get("master_deck", []), "card_backend_circuit_breaker") == circuit_count_before - 1, "executor remove card updates run deck")
	_check(run.get("deck_state", {}).get("removed_cards", []).has("card_backend_circuit_breaker"), "executor remove card records removed card")

	run = run_session.create_new_run("tester", true)
	battle = _start_first_battle(run, content, map, executor)
	var enemies: Array = battle.battle_state.get("enemies", [])
	if enemies.size() == 1:
		enemies.append(enemies[0].duplicate(true))
		enemies[1]["name"] = "测试副目标"
		enemies[1]["current_hp"] = 20
	battle.battle_state["enemies"] = enemies
	executor.execute([{ "effect_type": "deal_damage", "target_type": "all_enemies", "params": { "amount": 3 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(battle.battle_state["enemies"][0].get("current_hp", 0)) < int(battle.battle_state["enemies"][0].get("max_hp", 0)), "all enemies damages first target")
	_check(int(battle.battle_state["enemies"][1].get("current_hp", 0)) == 17, "all enemies damages second target")
	battle.select_target(1)
	_check(battle.selected_target_index() == 1, "battle target selection records index")
	var second_before := int(battle.battle_state["enemies"][1].get("current_hp", 0))
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_tester_defect_log"]
	player["current_energy"] = 3
	battle.play_card(run, 0, battle.selected_target_index())
	_check(int(battle.battle_state["enemies"][1].get("current_hp", 0)) < second_before, "selected target receives card damage")
	battle.battle_state["enemies"][0]["status_list"] = {}
	battle.battle_state["enemies"][1]["status_list"] = {}
	player["class_resource_state"]["bugs"] = 0
	player["class_resource_state"]["cases"] = 0
	player["hand"] = ["card_tester_repro_steps"]
	player["current_energy"] = 3
	battle.select_target(1)
	battle.play_card(run, 0, battle.selected_target_index())
	var repro_primary_status: Dictionary = battle.battle_state["enemies"][0].get("status_list", {})
	var repro_selected_status: Dictionary = battle.battle_state["enemies"][1].get("status_list", {})
	var tester_resources: Dictionary = player.get("class_resource_state", {})
	_check(int(repro_primary_status.get("bug", 0)) == 0, "tester repro steps ignores unselected target")
	_check(int(repro_selected_status.get("bug", 0)) >= 1, "tester repro steps injects bug into selected target")
	_check(int(repro_selected_status.get("case_mark", 0)) >= 1, "tester repro steps triggers starter relic case")
	_check(int(tester_resources.get("bugs", 0)) >= 1, "tester repro steps syncs bug resource")
	_check(int(tester_resources.get("cases", 0)) >= 1, "tester repro steps syncs case resource")
	battle.battle_state["enemies"][0]["status_list"] = {}
	player["class_resource_state"]["bugs"] = 0
	player["class_resource_state"]["cases"] = 0
	player["relic_runtime_flags"] = {}
	executor.execute([{ "effect_type": "inject_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	var status: Dictionary = battle.battle_state["enemies"][0].get("status_list", {})
	_check(int(status.get("bug", 0)) >= 1, "tester injects bug")
	_check(int(status.get("case_mark", 0)) >= 1, "tester starter relic adds case")
	tester_resources = player.get("class_resource_state", {})
	_check(int(tester_resources.get("bugs", 0)) >= 1, "tester bug status syncs resource")
	_check(int(tester_resources.get("cases", 0)) >= 1, "tester case status syncs resource")
	status["diff"] = 2
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "attack", "amount": 8 }
	player["class_resource_state"]["diff_tags"] = 2
	var bug_before := int(status.get("bug", 0))
	executor.execute([{ "effect_type": "inject_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	status = battle.battle_state["enemies"][0].get("status_list", {})
	tester_resources = player.get("class_resource_state", {})
	_check(int(status.get("bug", 0)) == bug_before + 2, "diff adds extra bug during reproduction")
	_check(int(status.get("diff", 0)) == 1, "diff is consumed by bug reproduction")
	_check(int(tester_resources.get("diff_tags", 0)) == 1, "diff resource decrements after reproduction")
	_check(int(battle.battle_state["enemies"][0].get("intent", {}).get("amount", 0)) == 4, "diff-boosted bug weakens intent by final bug amount")

	run = run_session.create_new_run("tester", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var fatal_bug_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	fatal_bug_enemy["status_list"] = { "diff": 2 }
	fatal_bug_enemy["intent"] = { "intent_type": "attack", "amount": 14 }
	player["class_resource_state"]["bugs"] = 0
	player["class_resource_state"]["diff_tags"] = 2
	player["hand"] = ["card_tester_92_bugs"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(fatal_bug_enemy.get("status_list", {}).get("bug", 0)) == 6, "tester fatal bug submission injects multiple bug stacks")
	_check(int(fatal_bug_enemy.get("status_list", {}).get("diff", 0)) == 0, "tester fatal bug submission consumes diff across hits")
	_check(int(player.get("class_resource_state", {}).get("bugs", 0)) == 6, "tester fatal bug submission syncs bug resource")
	_check(int(player.get("class_resource_state", {}).get("diff_tags", 0)) == 0, "tester fatal bug submission syncs consumed diff")
	_check(int(fatal_bug_enemy.get("intent", {}).get("amount", 0)) == 2, "tester fatal bug submission weakens intent per injected bug")

	run = run_session.create_new_run("tester", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var boundary_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	boundary_enemy["max_hp"] = 40
	boundary_enemy["current_hp"] = 18
	boundary_enemy["current_block"] = 0
	boundary_enemy["status_list"] = {}
	boundary_enemy["intent"] = { "intent_type": "attack", "amount": 4 }
	player["class_resource_state"]["cases"] = 0
	player["hand"] = ["card_tester_boundary_check"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(boundary_enemy.get("status_list", {}).get("case_mark", 0)) == 2, "tester boundary check adds bonus case to low hp target")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 2, "tester boundary check syncs low hp bonus cases")
	boundary_enemy["current_hp"] = 40
	boundary_enemy["status_list"] = {}
	boundary_enemy["intent"] = { "intent_type": "attack", "amount": 4 }
	player["class_resource_state"]["cases"] = 0
	executor.execute([{ "effect_type": "boundary_check", "target_type": "selected", "params": { "amount": 1, "bonus_amount": 1, "low_hp_percent": 50, "high_attack_threshold": 10 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(boundary_enemy.get("status_list", {}).get("case_mark", 0)) == 1, "tester boundary check adds base case without boundary")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 1, "tester boundary check syncs base cases")
	boundary_enemy["status_list"] = {}
	boundary_enemy["intent"] = { "intent_type": "multi_attack", "amount": 4, "hits": 3 }
	player["class_resource_state"]["cases"] = 0
	executor.execute([{ "effect_type": "boundary_check", "target_type": "selected", "params": { "amount": 1, "bonus_amount": 1, "low_hp_percent": 50, "high_attack_threshold": 10 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(boundary_enemy.get("status_list", {}).get("case_mark", 0)) == 2, "tester boundary check adds bonus case to high attack target")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 2, "tester boundary check syncs high attack bonus cases")

	run = run_session.create_new_run("tester", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var report_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	report_enemy["current_hp"] = 80
	report_enemy["current_block"] = 0
	report_enemy["status_list"] = { "bug": 3, "case_mark": 2, "diff": 1 }
	player["hand"] = ["card_tester_report_lock"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(report_enemy.get("current_hp", 0)) == 57, "tester report lock scales bug case and diff damage")

	run = run_session.create_new_run("tester", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var regression_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	regression_enemy["current_hp"] = 40
	regression_enemy["current_block"] = 0
	regression_enemy["status_list"] = { "bug": 2 }
	player["hand"] = ["card_tester_auto_regression"]
	player["current_energy"] = 3
	player["class_resource_state"]["cases"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("auto_regression", 0)) == 1, "tester auto regression status is applied")
	battle.call("_round_end_triggers", run)
	_check(int(regression_enemy.get("current_hp", 0)) == 36, "tester auto regression triggers bug damage at round end")
	_check(int(regression_enemy.get("status_list", {}).get("case_mark", 0)) == 1, "tester auto regression adds case to bugged target")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 1, "tester auto regression syncs case resource")

	run = run_session.create_new_run("tester", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var upgrade_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	upgrade_enemy["status_list"] = { "bug": 1 }
	upgrade_enemy["intent"] = { "intent_type": "attack", "amount": 8 }
	player["class_resource_state"]["bugs"] = 1
	player["hand"] = ["card_tester_bug_upgrade"]
	player["current_energy"] = 3
	player["current_block"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) >= 6, "tester bug upgrade grants block")
	_check(int(upgrade_enemy.get("status_list", {}).get("bug", 0)) == 2, "tester bug upgrade adds bug to existing bug")
	_check(int(player.get("class_resource_state", {}).get("bugs", 0)) == 2, "tester bug upgrade syncs bug resource")
	_check(int(upgrade_enemy.get("intent", {}).get("amount", 0)) == 6, "tester bug upgrade weakens intent by upgraded bug")
	upgrade_enemy["status_list"] = {}
	player["class_resource_state"]["bugs"] = 0
	executor.execute([{ "effect_type": "upgrade_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(upgrade_enemy.get("status_list", {}).get("bug", 0)) == 0, "tester bug upgrade needs an existing bug")

	run = run_session.create_new_run("tester", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var confirm_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	confirm_enemy["status_list"] = { "case_mark": 2 }
	player["class_resource_state"]["diff_tags"] = 0
	player["hand"] = ["card_tester_regression_confirm"]
	player["draw_pile"] = ["card_tester_smoke_test"]
	player["current_energy"] = 3
	battle.play_card(run, 0, 0)
	_check(int(confirm_enemy.get("status_list", {}).get("diff", 0)) == 1, "tester regression confirm adds diff to cased target")
	_check(int(player.get("class_resource_state", {}).get("diff_tags", 0)) == 1, "tester regression confirm syncs diff resource")
	_check(player.get("hand", []).has("card_tester_smoke_test"), "tester regression confirm draws on cased target")
	confirm_enemy["status_list"] = {}
	var confirm_hand_size := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "confirm_regression", "target_type": "selected", "params": { "amount": 1, "draw_amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(confirm_enemy.get("status_list", {}).get("diff", 0)) == 0, "tester regression confirm needs an existing case")
	_check(int(player.get("hand", []).size()) == confirm_hand_size, "tester regression confirm does not draw without case")

	run = run_session.create_new_run("tester", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var smoke_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	smoke_enemy["status_list"] = {}
	player["hand"] = ["card_tester_smoke_test"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["diff_tags"] = 0
	battle.play_card(run, 0, 0)
	var smoke_flags: Dictionary = smoke_enemy.get("runtime_flags", {})
	var observed_intent: Dictionary = smoke_flags.get("observed_next_intent", {}).duplicate(true)
	_check(int(player.get("current_block", 0)) >= 8, "tester smoke test grants configured block")
	_check(not observed_intent.is_empty(), "tester smoke test stores next intent preview")
	_check(not String(smoke_flags.get("observed_next_intent_text", "")).is_empty(), "tester smoke test stores readable preview")
	_check(int(smoke_enemy.get("status_list", {}).get("diff", 0)) == 0, "tester smoke test does not add diff in combat")
	_check(int(player.get("class_resource_state", {}).get("diff_tags", 0)) == 0, "tester smoke test does not sync diff resource")
	if not observed_intent.is_empty():
		battle.call("_roll_enemy_intents")
		_check(smoke_enemy.get("intent", {}) == observed_intent, "tester smoke test next intent resolves from preview")
		_check(not smoke_enemy.get("runtime_flags", {}).has("observed_next_intent"), "tester smoke test preview is consumed")

	run = run_session.create_new_run("tester", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var matrix_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	matrix_enemy["status_list"] = {}
	player["hand"] = ["card_tester_case_matrix"]
	player["current_energy"] = 3
	player["class_resource_state"]["cases"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("case_matrix", 0)) == 1, "tester case matrix status is applied")
	executor.execute([{ "effect_type": "add_case", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(matrix_enemy.get("status_list", {}).get("case_mark", 0)) == 2, "tester case matrix doubles first case each turn")
	_check(int(player.get("class_resource_state", {}).get("cases", 0)) == 2, "tester case matrix syncs bonus case resource")
	executor.execute([{ "effect_type": "add_case", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(matrix_enemy.get("status_list", {}).get("case_mark", 0)) == 3, "tester case matrix triggers only once per turn")
	battle.call("_start_player_turn", run, false)
	executor.execute([{ "effect_type": "add_case", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(matrix_enemy.get("status_list", {}).get("case_mark", 0)) == 5, "tester case matrix resets on next turn")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var style_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	style_enemy["current_hp"] = 50
	style_enemy["current_block"] = 0
	style_enemy["status_list"] = {}
	player["class_resource_state"]["style_layers"] = 2
	player["status_list"] = {}
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(style_enemy.get("current_hp", 0)) == 43, "style layer resource boosts damage")
	_check(int(player.get("class_resource_state", {}).get("style_layers", 0)) == 1, "style layer resource is consumed after damage")
	style_enemy["current_hp"] = 50
	player["class_resource_state"]["style_layers"] = 0
	player["status_list"] = { "style_layer": 3 }
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 5 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(style_enemy.get("current_hp", 0)) == 42, "style layer status boosts damage")
	_check(int(player.get("status_list", {}).get("style_layer", 0)) == 2, "style layer status is consumed after damage")

	run = run_session.create_new_run("product_manager", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["draw_pile"] = ["card_pm_change_wording"]
	var hand_before := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) >= 4, "pm starter relic grants block")
	_check(int(player.get("hand", []).size()) == hand_before + 1, "pm starter relic draws")
	var pm_resources: Dictionary = player.get("class_resource_state", {})
	_check(int(pm_resources.get("requirement_change_marks", 0)) >= 1, "pm requirement change syncs resource")
	executor.execute([{ "effect_type": "apply_status", "target_type": "self", "params": { "status_id": "priority", "amount": 2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	pm_resources = player.get("class_resource_state", {})
	_check(int(pm_resources.get("priority_targets", 0)) >= 2, "pm priority status syncs resource")
	_check(not battle.card_needs_target("card_pm_schedule_compress"), "pm priority attack auto resolves target")
	var pm_enemies: Array = battle.battle_state.get("enemies", [])
	if pm_enemies.size() == 1:
		pm_enemies.append(pm_enemies[0].duplicate(true))
		pm_enemies[1]["name"] = "高优先级目标"
	pm_enemies[0]["current_hp"] = 50
	pm_enemies[0]["current_block"] = 0
	pm_enemies[0]["status_list"] = {}
	pm_enemies[1]["current_hp"] = 50
	pm_enemies[1]["current_block"] = 0
	pm_enemies[1]["status_list"] = { "priority": 3 }
	battle.battle_state["enemies"] = pm_enemies
	player["hand"] = ["card_pm_schedule_compress"]
	player["current_energy"] = 3
	battle.select_target(0)
	battle.play_card(run, 0, 0)
	_check(int(battle.battle_state["enemies"][0].get("current_hp", 0)) == 50, "pm priority attack ignores selected low priority target")
	_check(int(battle.battle_state["enemies"][1].get("current_hp", 0)) < 50, "pm priority attack hits highest priority target")
	_check(int(battle.battle_state["enemies"][1].get("status_list", {}).get("requirement_change", 0)) >= 1, "pm priority attack marks hit target")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var change_wording_enemies: Array = battle.battle_state.get("enemies", [])
	if change_wording_enemies.size() == 1:
		change_wording_enemies.append(change_wording_enemies[0].duplicate(true))
		change_wording_enemies[1]["name"] = "被改口目标"
	change_wording_enemies[0]["intent"] = { "intent_type": "attack", "amount": 10 }
	change_wording_enemies[0]["status_list"] = {}
	change_wording_enemies[1]["intent"] = { "intent_type": "attack", "amount": 10 }
	change_wording_enemies[1]["status_list"] = {}
	battle.battle_state["enemies"] = change_wording_enemies
	player["hand"] = ["card_pm_change_wording"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 1)
	_check(int(change_wording_enemies[0].get("intent", {}).get("amount", 0)) == 10, "pm change wording ignores unselected enemy")
	_check(int(change_wording_enemies[1].get("intent", {}).get("amount", 0)) == 6, "pm change wording lowers selected attack intent")
	_check(int(player.get("current_block", 0)) == 0, "pm change wording does not grant generic block")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var meeting_change_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	meeting_change_enemy["intent"] = { "intent_type": "attack", "amount": 10 }
	player["hand"] = ["card_pm_meeting_minutes", "card_pm_change_wording"]
	player["draw_pile"] = ["card_pm_revision_notice"]
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("meeting_minutes_boost", 0)) == 1, "pm meeting minutes stores one boost")
	_check(player.get("hand", []).has("card_pm_revision_notice"), "pm meeting minutes draws a card")
	_check(int(player.get("current_block", 0)) == 0, "pm meeting minutes does not grant generic block")
	battle.play_card(run, 0, 0)
	_check(int(meeting_change_enemy.get("intent", {}).get("amount", 0)) == 4, "pm meeting minutes strengthens next wording change")
	_check(int(player.get("status_list", {}).get("meeting_minutes_boost", 0)) == 0, "pm wording boost is consumed")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var revision_enemies: Array = battle.battle_state.get("enemies", [])
	if revision_enemies.size() == 1:
		revision_enemies.append(revision_enemies[0].duplicate(true))
		revision_enemies[1]["name"] = "改版目标"
	revision_enemies[0]["status_list"] = {}
	revision_enemies[1]["status_list"] = {}
	battle.battle_state["enemies"] = revision_enemies
	player["hand"] = ["card_pm_revision_notice"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	player["class_resource_state"]["requirement_change_marks"] = 0
	battle.play_card(run, 0, 1)
	_check(int(revision_enemies[0].get("status_list", {}).get("requirement_change", 0)) == 0, "pm revision notice ignores unselected enemy")
	_check(int(revision_enemies[1].get("status_list", {}).get("requirement_change", 0)) == 1, "pm revision notice marks selected enemy")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) == 1, "pm revision notice syncs requirement resource")
	_check(int(player.get("current_block", 0)) == 0, "pm revision notice does not grant generic block")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var meeting_revision_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	meeting_revision_enemy["status_list"] = {}
	player["hand"] = ["card_pm_meeting_minutes", "card_pm_revision_notice"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["status_list"] = {}
	player["class_resource_state"]["requirement_change_marks"] = 0
	battle.play_card(run, 0, 0)
	battle.play_card(run, 0, 0)
	_check(int(meeting_revision_enemy.get("status_list", {}).get("requirement_change", 0)) == 2, "pm meeting minutes strengthens revision notice")
	_check(int(player.get("status_list", {}).get("meeting_minutes_boost", 0)) == 0, "pm revision boost is consumed")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) == 2, "pm boosted revision syncs requirement resource")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var review_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	review_enemy["intent"] = { "intent_type": "attack", "amount": 12 }
	player["hand"] = ["card_pm_review"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("pm_review", 0)) == 1, "pm review status is applied")
	_check(int(player.get("current_block", 0)) == 0, "pm review does not grant immediate block")
	player["draw_pile"] = ["card_pm_change_wording", "card_pm_priority_shuffle"]
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) == 4, "pm review grants block on first intent change")
	_check(player.get("hand", []).has("card_pm_priority_shuffle"), "pm review draws on first intent change")
	_check(bool(player.get("relic_runtime_flags", {}).get("pm_review_used_this_turn", false)), "pm review records turn trigger")
	var review_hand_after_first := int(player.get("hand", []).size())
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) == 4, "pm review triggers only once per turn")
	_check(int(player.get("hand", []).size()) == review_hand_after_first, "pm review does not draw twice in one turn")
	player["hand"] = []
	player["draw_pile"] = []
	player["discard_pile"] = []
	battle.call("_start_player_turn", run, false)
	review_enemy["intent"] = { "intent_type": "attack", "amount": 12 }
	player["draw_pile"] = ["card_pm_revision_notice"]
	executor.execute([{ "effect_type": "modify_intent", "target_type": "selected", "params": { "amount": -2 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(player.get("current_block", 0)) == 4, "pm review resets next turn and grants block again")
	_check(player.get("hand", []).has("card_pm_revision_notice"), "pm review draws again after round reset")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var delay_enemies: Array = battle.battle_state.get("enemies", [])
	if delay_enemies.size() == 1:
		delay_enemies.append(delay_enemies[0].duplicate(true))
		delay_enemies[1]["name"] = "延期目标"
	delay_enemies[0]["intent"] = { "intent_type": "attack", "amount": 18 }
	delay_enemies[0]["runtime_flags"] = {}
	delay_enemies[1]["intent"] = { "intent_type": "attack", "amount": 18 }
	delay_enemies[1]["runtime_flags"] = {}
	battle.battle_state["enemies"] = delay_enemies
	player["hand"] = ["card_pm_delay_meeting"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 1)
	_check(int(delay_enemies[0].get("intent", {}).get("amount", 0)) == 18, "pm delay meeting ignores unselected enemy")
	_check(delay_enemies[1].get("intent", {}).get("intent_type", "") == "block", "pm delay meeting replaces selected intent this turn")
	_check(int(delay_enemies[1].get("intent", {}).get("amount", 0)) == 3, "pm delay meeting changes selected target to low yield block")
	_check(int(delay_enemies[1].get("runtime_flags", {}).get("forced_next_intent", {}).get("amount", 0)) == 18, "pm delay meeting stores delayed intent")
	_check(int(player.get("current_block", 0)) == 0, "pm delay meeting does not grant generic block")
	battle.call("_roll_enemy_intents")
	_check(delay_enemies[1].get("intent", {}).get("intent_type", "") == "attack", "pm delayed intent returns next turn")
	_check(int(delay_enemies[1].get("intent", {}).get("amount", 0)) == 18, "pm delayed intent preserves original amount")
	_check(not delay_enemies[1].get("runtime_flags", {}).has("forced_next_intent"), "pm delayed intent is consumed after return")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var split_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	split_enemy["intent"] = { "intent_type": "attack", "amount": 18 }
	split_enemy["runtime_flags"] = {}
	player["hand"] = ["card_pm_milestone_split"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(split_enemy.get("intent", {}).get("intent_type", "") == "multi_attack", "pm milestone split converts strong attack to multi attack")
	_check(int(split_enemy.get("intent", {}).get("hits", 0)) == 3, "pm milestone split uses configured hit count")
	_check(int(split_enemy.get("intent", {}).get("amount", 0)) == 6, "pm milestone split lowers each hit amount")
	_check(int(player.get("current_block", 0)) == 0, "pm milestone split does not grant generic block")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var roadmap_enemies: Array = battle.battle_state.get("enemies", [])
	if roadmap_enemies.size() == 1:
		roadmap_enemies.append(roadmap_enemies[0].duplicate(true))
		roadmap_enemies[1]["name"] = "路线图主目标"
	roadmap_enemies[0]["current_hp"] = 60
	roadmap_enemies[0]["current_block"] = 0
	roadmap_enemies[0]["status_list"] = { "requirement_change": 5 }
	roadmap_enemies[1]["current_hp"] = 60
	roadmap_enemies[1]["current_block"] = 0
	roadmap_enemies[1]["status_list"] = { "priority": 4, "requirement_change": 3 }
	battle.battle_state["enemies"] = roadmap_enemies
	player["hand"] = ["card_pm_roadmap"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.select_target(0)
	battle.play_card(run, 0, battle.selected_target_index())
	_check(int(roadmap_enemies[0].get("current_hp", 0)) == 60, "pm roadmap ignores selected low priority target")
	_check(int(roadmap_enemies[1].get("current_hp", 0)) == 37, "pm roadmap scales damage from requirement changes")
	_check(int(roadmap_enemies[1].get("status_list", {}).get("requirement_change", 0)) == 3, "pm roadmap does not add generic requirement mark")
	_check(int(player.get("current_energy", 0)) == 1, "pm roadmap charges card cost")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var align_enemies: Array = battle.battle_state.get("enemies", [])
	if align_enemies.size() == 1:
		align_enemies.append(align_enemies[0].duplicate(true))
		align_enemies[1]["name"] = "对齐副目标"
	align_enemies[0]["current_hp"] = 50
	align_enemies[0]["intent"] = { "intent_type": "attack", "amount": 99 }
	align_enemies[0]["runtime_flags"] = {
		"forced_next_intent": { "intent_type": "attack", "amount": 88 },
		"observed_next_intent": { "intent_type": "block", "amount": 77 },
		"observed_next_intent_text": "防守 77",
	}
	align_enemies[1]["current_hp"] = 50
	align_enemies[1]["intent"] = { "intent_type": "block", "amount": 77 }
	align_enemies[1]["runtime_flags"] = {
		"forced_next_intent": { "intent_type": "attack", "amount": 66 },
		"observed_next_intent": { "intent_type": "attack", "amount": 55 },
		"observed_next_intent_text": "攻击 55",
	}
	battle.battle_state["enemies"] = align_enemies
	player["hand"] = ["card_pm_align_all"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(align_enemies[0].get("intent", {}).get("intent_type", "") != "attack" or int(align_enemies[0].get("intent", {}).get("amount", 0)) != 99, "pm align all rerolls first enemy intent")
	_check(align_enemies[1].get("intent", {}).get("intent_type", "") != "block" or int(align_enemies[1].get("intent", {}).get("amount", 0)) != 77, "pm align all rerolls second enemy intent")
	_check(not align_enemies[0].get("runtime_flags", {}).has("forced_next_intent"), "pm align all clears first forced intent")
	_check(not align_enemies[0].get("runtime_flags", {}).has("observed_next_intent"), "pm align all clears first observed intent")
	_check(not align_enemies[1].get("runtime_flags", {}).has("forced_next_intent"), "pm align all clears second forced intent")
	_check(not align_enemies[1].get("runtime_flags", {}).has("observed_next_intent"), "pm align all clears second observed intent")
	_check(int(player.get("current_block", 0)) == 0, "pm align all does not grant generic block")
	_check(int(player.get("current_energy", 0)) == 1, "pm align all charges card cost")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var priority_shuffle_enemies: Array = battle.battle_state.get("enemies", [])
	if priority_shuffle_enemies.size() == 1:
		priority_shuffle_enemies.append(priority_shuffle_enemies[0].duplicate(true))
		priority_shuffle_enemies[1]["name"] = "次要优先级目标"
	priority_shuffle_enemies[0]["current_hp"] = 50
	priority_shuffle_enemies[0]["current_block"] = 0
	priority_shuffle_enemies[0]["status_list"] = {}
	priority_shuffle_enemies[1]["current_hp"] = 50
	priority_shuffle_enemies[1]["current_block"] = 0
	priority_shuffle_enemies[1]["status_list"] = { "priority": 5 }
	battle.battle_state["enemies"] = priority_shuffle_enemies
	player["hand"] = ["card_pm_priority_shuffle", "card_pm_schedule_compress"]
	player["draw_pile"] = []
	player["discard_pile"] = []
	player["current_energy"] = 2
	player["current_block"] = 0
	player["class_resource_state"]["priority_targets"] = 5
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) == 8, "pm priority shuffle grants configured block")
	_check(int(priority_shuffle_enemies[0].get("status_list", {}).get("priority", 0)) == 3, "pm priority shuffle promotes selected target")
	_check(int(priority_shuffle_enemies[1].get("status_list", {}).get("priority", 0)) == 1, "pm priority shuffle demotes other targets")
	_check(int(player.get("class_resource_state", {}).get("priority_targets", 0)) == 4, "pm priority shuffle recomputes priority resource")
	battle.play_card(run, 0, 1)
	_check(int(priority_shuffle_enemies[0].get("current_hp", 0)) < 50, "pm priority shuffle redirects next priority attack")
	_check(int(priority_shuffle_enemies[1].get("current_hp", 0)) == 50, "pm priority shuffle prevents stale priority from controlling target")

	run = run_session.create_new_run("product_manager", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var priority_top_enemies: Array = battle.battle_state.get("enemies", [])
	if priority_top_enemies.size() == 1:
		priority_top_enemies.append(priority_top_enemies[0].duplicate(true))
		priority_top_enemies[1]["name"] = "原高优先级目标"
	priority_top_enemies[0]["current_hp"] = 50
	priority_top_enemies[0]["current_block"] = 0
	priority_top_enemies[0]["status_list"] = {}
	priority_top_enemies[1]["current_hp"] = 50
	priority_top_enemies[1]["current_block"] = 0
	priority_top_enemies[1]["status_list"] = { "priority": 4 }
	battle.battle_state["enemies"] = priority_top_enemies
	player["hand"] = ["card_pm_priority_top", "card_pm_schedule_compress"]
	player["draw_pile"] = ["card_pm_change_wording"]
	player["discard_pile"] = []
	player["current_energy"] = 1
	player["class_resource_state"]["priority_targets"] = 4
	battle.play_card(run, 0, 0)
	_check(int(priority_top_enemies[0].get("status_list", {}).get("priority", 0)) == 5, "pm priority top raises selected target above old priority")
	_check(int(priority_top_enemies[1].get("status_list", {}).get("priority", 0)) == 0, "pm priority top clears old priority target")
	_check(int(player.get("class_resource_state", {}).get("priority_targets", 0)) == 5, "pm priority top recomputes priority resource")
	_check(player.get("hand", []).has("card_pm_change_wording"), "pm priority top draws a card")
	battle.play_card(run, 0, 1)
	_check(int(priority_top_enemies[0].get("current_hp", 0)) < 50, "pm priority top redirects next priority attack to selected target")
	_check(int(priority_top_enemies[1].get("current_hp", 0)) == 50, "pm priority top prevents old target from staying highest priority")

	run = run_session.create_new_run("product_manager", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var changed_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	changed_enemy["current_hp"] = 50
	changed_enemy["current_block"] = 0
	changed_enemy["intent"] = { "intent_type": "attack", "amount": 10 }
	changed_enemy["status_list"] = { "requirement_change": 2 }
	battle.battle_state["enemies"] = [changed_enemy]
	player["current_spirit"] = 50
	player["current_block"] = 0
	player["status_list"] = {}
	player["class_resource_state"]["requirement_change_marks"] = 2
	battle.call("_enemy_turn", run)
	_check(int(player.get("current_spirit", 0)) == 44, "requirement change reduces next attack before enemy action")
	_check(int(changed_enemy.get("status_list", {}).get("requirement_change", 0)) == 1, "requirement change consumes one stack before action")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) == 1, "requirement change resource syncs after consumption")

	run = run_session.create_new_run("product_manager", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var spread_enemies: Array = battle.battle_state.get("enemies", [])
	if spread_enemies.size() == 1:
		spread_enemies.append(spread_enemies[0].duplicate(true))
		spread_enemies[1]["name"] = "被蔓延目标"
	spread_enemies[0]["status_list"] = {}
	spread_enemies[1]["status_list"] = {}
	battle.battle_state["enemies"] = spread_enemies
	player["status_list"] = { "scope_spread": 1 }
	player["class_resource_state"]["requirement_change_marks"] = 0
	executor.execute([{ "effect_type": "apply_status", "target_type": "selected", "params": { "status_id": "requirement_change", "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(spread_enemies[0].get("status_list", {}).get("requirement_change", 0)) == 1, "scope spread keeps original requirement target")
	_check(int(spread_enemies[1].get("status_list", {}).get("requirement_change", 0)) == 1, "scope spread adds requirement change to another enemy")
	_check(int(player.get("class_resource_state", {}).get("requirement_change_marks", 0)) >= 2, "scope spread syncs spread requirement resource")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var linear_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	linear_enemy["current_hp"] = 40
	linear_enemy["current_block"] = 0
	player["hand"] = ["card_algo_linear_probe"]
	player["current_energy"] = 3
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 0
	battle.play_card(run, 0, 0)
	_check(int(linear_enemy.get("current_hp", 0)) == 30, "algorithm linear probe deals starter damage")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 1, "algorithm linear probe gains compute")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 1, "algorithm linear probe compute raises complexity")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_complexity_compress"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["complexity"] = 4
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_block", 0)) >= 8, "algorithm starter complexity compress grants block")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 2, "algorithm starter complexity compress reduces complexity")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_heuristic_search"]
	player["draw_pile"] = ["card_algo_linear_probe"]
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 0
	battle.play_card(run, 0, 0)
	_check(player.get("hand", []).has("card_algo_linear_probe"), "algorithm heuristic search draws a card")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 1, "algorithm heuristic search gains compute")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 1, "algorithm heuristic search compute raises complexity")
	_check(int(player.get("current_block", 0)) == 0, "algorithm heuristic search does not grant generic block")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_dynamic_programming", "card_algo_complexity_compress", "card_algo_pruning"]
	player["draw_pile"] = ["card_algo_linear_probe"]
	player["discard_pile"] = []
	player["current_energy"] = 10
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 0
	player["status_list"] = {}
	battle.battle_state["runtime_flags"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("status_list", {}).get("dynamic_programming", 0)) == 1, "algorithm dynamic programming status is applied")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm dynamic programming has no immediate compute")
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm dynamic programming ignores first skill")
	_check(not player.get("hand", []).has("card_algo_linear_probe"), "algorithm dynamic programming does not draw on first skill")
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 1, "algorithm dynamic programming gains compute on repeated skill")
	_check(player.get("hand", []).has("card_algo_linear_probe"), "algorithm dynamic programming draws on repeated skill")
	_check(battle.battle_state.get("runtime_flags", {}).get("dynamic_programming_triggered_types", []).has("skill"), "algorithm dynamic programming records triggered type")
	player["hand"] = ["card_algo_local_opt"]
	player["draw_pile"] = ["card_algo_global_optimum"]
	player["current_energy"] = 10
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 1, "algorithm dynamic programming does not repeat same type compute")
	_check(not player.get("hand", []).has("card_algo_global_optimum"), "algorithm dynamic programming does not draw twice for same type")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var local_opt_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	local_opt_enemy["current_hp"] = 60
	local_opt_enemy["current_block"] = 0
	player["hand"] = ["card_algo_local_opt", "card_algo_complexity_burst"]
	player["current_energy"] = 1
	player["class_resource_state"]["complexity"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 2, "algorithm local optimum reduces complexity")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 1, "algorithm local optimum grants next-card discount")
	_check(battle.hand_card_cost(0) == 1, "algorithm local optimum previews discounted next card")
	_check(battle.can_play_card(0), "algorithm local optimum enables discounted next card")
	battle.play_card(run, 0, 0)
	_check(int(local_opt_enemy.get("current_hp", 0)) == 44, "algorithm local optimum discount lets next card resolve")
	_check(int(player.get("current_energy", 0)) == 0, "algorithm local optimum discount charges reduced cost")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 0, "algorithm local optimum discount is consumed")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var optimum_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	optimum_enemy["current_hp"] = 80
	optimum_enemy["current_block"] = 0
	player["hand"] = ["card_algo_global_optimum"]
	player["current_energy"] = 3
	player["class_resource_state"]["compute"] = 4
	battle.play_card(run, 0, 0)
	_check(int(optimum_enemy.get("current_hp", 0)) == 46, "algorithm x finisher spends energy and compute for damage")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm x finisher consumes stored compute")
	_check(int(player.get("current_energy", 0)) == 1, "algorithm starter relic refunds first x card")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var burst_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	burst_enemy["current_hp"] = 60
	burst_enemy["current_block"] = 0
	player["hand"] = ["card_algo_complexity_burst"]
	player["current_energy"] = 3
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 5
	battle.play_card(run, 0, 0)
	_check(int(burst_enemy.get("current_hp", 0)) == 32, "algorithm complexity burst scales damage from complexity")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 5, "algorithm complexity burst keeps complexity")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm complexity burst does not add generic compute")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var pruning_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	pruning_enemy["current_hp"] = 60
	pruning_enemy["current_block"] = 0
	player["hand"] = ["card_algo_pruning", "card_algo_complexity_burst"]
	player["current_energy"] = 2
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 3
	player["status_list"] = {}
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 1, "algorithm pruning reduces complexity")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 1, "algorithm pruning grants next-card discount")
	_check(battle.hand_card_cost(0) == 1, "algorithm pruning previews discounted next card")
	_check(battle.can_play_card(0), "algorithm pruning enables discounted next card")
	battle.play_card(run, 0, 0)
	_check(int(pruning_enemy.get("current_hp", 0)) == 48, "algorithm pruning discount lets next card resolve")
	_check(int(player.get("current_energy", 0)) == 0, "algorithm pruning discount charges reduced cost")
	_check(int(player.get("status_list", {}).get("cost_reduction", 0)) == 0, "algorithm pruning discount is consumed")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_big_o_compress"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 0
	player["class_resource_state"]["complexity"] = 4
	battle.play_card(run, 0, 0)
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 1, "algorithm big O compress spends stored complexity")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 3, "algorithm big O compress converts complexity to compute")
	_check(int(player.get("current_block", 0)) == 6, "algorithm big O compress converts complexity to block")
	_check(int(player.get("current_energy", 0)) == 2, "algorithm big O compress charges card cost")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_monte_carlo"]
	player["draw_pile"] = ["card_algo_linear_probe"]
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["complexity"] = 2
	battle.play_card(run, 0, 0)
	var monte_candidates := ["card_algo_greedy_sample", "card_algo_state_compress", "card_algo_hash_accel", "card_algo_eval_func"]
	var monte_generated := false
	for generated_card_id in monte_candidates:
		if player.get("hand", []).has(generated_card_id):
			monte_generated = true
	_check(monte_generated, "algorithm monte carlo creates a scheme card in hand")
	_check(player.get("hand", []).has("card_algo_linear_probe"), "algorithm monte carlo draws a card")
	_check(int(player.get("current_block", 0)) == 0, "algorithm monte carlo does not grant generic block")
	_check(int(player.get("class_resource_state", {}).get("complexity", 0)) == 2, "algorithm monte carlo preserves complexity")
	_check(int(player.get("current_energy", 0)) == 2, "algorithm monte carlo charges card cost")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_algo_astar"]
	player["draw_pile"] = ["card_algo_heuristic_search", "card_algo_pruning", "card_algo_matrix_mul", "card_algo_dynamic_programming"]
	player["discard_pile"] = []
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 0
	battle.play_card(run, 0, 0)
	_check(player.get("hand", []).has("card_algo_matrix_mul"), "algorithm astar fetches matrix multiplication into hand")
	_check(not player.get("draw_pile", []).has("card_algo_matrix_mul"), "algorithm astar removes fetched key card from draw")
	_check(String(player.get("draw_pile", []).back()) == "card_algo_pruning", "algorithm astar puts priority card on top of draw pile")
	_check(int(player.get("current_block", 0)) == 0, "algorithm astar does not grant generic block")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 0, "algorithm astar does not add generic compute")
	_check(int(player.get("current_energy", 0)) == 2, "algorithm astar charges card cost")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var matrix_enemy_low: Dictionary = battle.battle_state.get("enemies", [])[0]
	matrix_enemy_low["current_hp"] = 120
	matrix_enemy_low["max_hp"] = 120
	matrix_enemy_low["current_block"] = 0
	matrix_enemy_low["status_list"] = {}
	player["hand"] = ["card_algo_matrix_mul"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 2
	player["class_resource_state"]["complexity"] = 0
	battle.play_card(run, 0, 0)
	_check(int(matrix_enemy_low.get("current_hp", 0)) == 102, "algorithm matrix multiplication low compute uses base damage")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 2, "algorithm matrix multiplication does not add compute")

	run = run_session.create_new_run("algorithm", true)
	run["owned_relic_ids"] = []
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var matrix_enemy_high: Dictionary = battle.battle_state.get("enemies", [])[0]
	matrix_enemy_high["current_hp"] = 120
	matrix_enemy_high["max_hp"] = 120
	matrix_enemy_high["current_block"] = 0
	matrix_enemy_high["status_list"] = {}
	player["hand"] = ["card_algo_matrix_mul"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["class_resource_state"]["compute"] = 4
	player["class_resource_state"]["complexity"] = 0
	battle.play_card(run, 0, 0)
	_check(int(matrix_enemy_high.get("current_hp", 0)) == 72, "algorithm matrix multiplication high compute gains burst damage")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 4, "algorithm matrix multiplication keeps compute after payoff")
	_check(int(player.get("current_energy", 0)) == 1, "algorithm matrix multiplication charges card cost")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_cold_brew_bucket")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_hotfix_rollback"]
	player["current_energy"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 1, "cold brew refunds first zero cost card")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_rollback"]
	player["current_energy"] = 3
	player["current_block"] = 0
	player["status_list"] = { "weak": 2, "vulnerable": 1, "anxiety": 1, "overtime": 1 }
	battle.play_card(run, 0, 0)
	var rollback_status: Dictionary = player.get("status_list", {})
	_check(int(player.get("current_block", 0)) >= 6, "shared rollback grants block")
	_check(not rollback_status.has("weak"), "shared rollback clears weak")
	_check(not rollback_status.has("vulnerable"), "shared rollback clears vulnerable")
	_check(not rollback_status.has("anxiety"), "shared rollback clears anxiety")
	_check(rollback_status.has("overtime"), "shared rollback keeps heavier overtime")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_standup"]
	player["draw_pile"] = ["card_shared_badge_throw"]
	player["discard_pile"] = []
	player["current_energy"] = 1
	player["current_block"] = 0
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 1, "shared standup refunds its energy")
	_check(player.get("hand", []).has("card_shared_badge_throw"), "shared standup draws a replacement")
	_check(int(player.get("current_block", 0)) >= 5, "shared standup grants block")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_shared_meeting_mute"]
	player["current_energy"] = 3
	var mute_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	mute_enemy["intent"] = { "intent_type": "attack", "amount": 9 }
	_check(battle.card_needs_target("card_shared_meeting_mute"), "shared meeting mute requests a target")
	battle.play_card(run, 0, 0)
	_check(int(mute_enemy.get("intent", {}).get("amount", 0)) == 5, "shared meeting mute reduces attack intent")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_read_replica")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["current_block"] = 0
	var cache_before := int(player.get("class_resource_state", {}).get("cache", 0))
	battle.call("_enemy_attack", player, battle.battle_state.get("enemies", [])[0], 6, run)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) > cache_before, "read replica returns cache on damage")

	run = run_session.create_new_run("tester", true)
	run["owned_relic_ids"].append("relic_error_log_repo")
	battle = _start_first_battle(run, content, map, executor)
	var error_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	var error_hp_before := int(error_enemy.get("current_hp", 0))
	executor.execute([{ "effect_type": "inject_bug", "target_type": "selected", "params": { "amount": 1 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(error_enemy.get("current_hp", 0)) < error_hp_before, "error log repo damages on bug")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	var status_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	status_enemy["current_block"] = 0
	status_enemy["current_hp"] = 50
	player["status_list"] = { "weak": 1 }
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 8 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(status_enemy.get("current_hp", 0)) == 44, "player weak reduces outgoing damage")
	status_enemy["current_hp"] = 50
	status_enemy["status_list"] = { "vulnerable": 1 }
	player["status_list"] = {}
	executor.execute([{ "effect_type": "deal_damage", "target_type": "selected", "params": { "amount": 8 } }], battle.battle_state, run, 0, battle.battle_state["log"])
	_check(int(status_enemy.get("current_hp", 0)) == 38, "enemy vulnerable increases outgoing damage")
	status_enemy["status_list"] = { "weak": 1 }
	player["status_list"] = { "vulnerable": 1 }
	player["current_spirit"] = 40
	player["current_block"] = 0
	battle.call("_enemy_attack", player, status_enemy, 8, run)
	_check(int(player.get("current_spirit", 0)) == 31, "enemy weak and player vulnerable modify incoming damage")
	battle.call("_round_end_triggers", run)
	_check(int(player.get("status_list", {}).get("vulnerable", 0)) == 0, "player short debuff decays at turn end")
	player["status_list"] = { "anxiety": 2 }
	player["current_energy"] = 3
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_energy", 0)) == 2, "anxiety reduces round start energy")
	_check(int(player.get("status_list", {}).get("anxiety", 0)) == 1, "anxiety decays after triggering")
	player["status_list"] = { "overtime": 2 }
	player["current_spirit"] = 40
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_spirit", 0)) == 38, "overtime damages at round start")
	_check(int(player.get("status_list", {}).get("overtime", 0)) == 1, "overtime decays after triggering")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["status_list"] = {}
	player["class_resource_state"] = { "compute": 0, "complexity": 3 }
	player["current_energy"] = 3
	player["current_spirit"] = 40
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_energy", 0)) == 2, "high complexity reduces round start energy")
	_check(int(player.get("current_spirit", 0)) == 40, "complexity pressure uses configured spirit loss")
	player["status_list"] = { "complexity": 4 }
	player["class_resource_state"] = { "compute": 0, "complexity": 1 }
	player["current_energy"] = 3
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("current_energy", 0)) == 2, "complexity status and resource do not double count")

	run = run_session.create_new_run("backend")
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["status_list"] = { "service_online": 2 }
	player["class_resource_state"] = { "services": 0, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "service online status adds cache at round start")
	_check(int(player.get("current_block", 0)) == 4, "service online status adds block at round start")
	player["class_resource_state"] = { "services": 2, "cache": 0 }
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "service online status and resource do not double count")
	player["status_list"] = { "service_online": 1, "sharding": 1 }
	player["class_resource_state"] = { "services": 0, "cache": 0 }
	player["relic_runtime_flags"] = {}
	player["current_block"] = 0
	battle.call("_round_start_triggers", run, false)
	_check(int(player.get("class_resource_state", {}).get("cache", 0)) == 2, "sharding boosts service online cache gain")
	player["status_list"] = {}
	player["class_resource_state"] = { "services": 2, "cache": 2 }
	var service_enemy: Dictionary = battle.battle_state.get("enemies", [])[0]
	service_enemy["current_hp"] = 30
	service_enemy["current_block"] = 0
	battle.call("_round_end_triggers", run)
	_check(int(service_enemy.get("current_hp", 0)) == 26, "service online damages enemies at round end")

	run = run_session.create_new_run("backend")
	run["deck_state"]["upgraded_cards"] = ["card_backend_interface_probe"]
	battle = _start_first_battle(run, content, map, executor)
	player = battle.battle_state.get("player", {})
	player["hand"] = ["card_backend_interface_probe"]
	player["current_energy"] = 3
	var target: Dictionary = battle.battle_state.get("enemies", [])[0]
	var hp_before := int(target.get("current_hp", 0))
	battle.play_card(run, 0, 0)
	_check(int(player.get("current_energy", 0)) == 3, "upgraded one-cost card costs zero")
	_check(hp_before - int(target.get("current_hp", 0)) >= 12, "upgraded card effect is stronger")

func _validate_enemy_intent_actions(config, content, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)

	var run := run_session.create_new_run("backend")
	var battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	var player: Dictionary = battle.battle_state.get("player", {})
	player["discard_pile"] = []
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "pollute", "card_id": "card_status_option_promise", "amount": 2, "destination": "discard" }
	battle.call("_enemy_turn", run)
	_check(_count_card(player.get("discard_pile", []), "card_status_option_promise") == 2, "enemy pollute adds status cards")

	run = run_session.create_new_run("frontend", true)
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	player = battle.battle_state.get("player", {})
	player["current_spirit"] = 40
	player["current_block"] = 2
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "multi_attack", "amount": 3, "hits": 3 }
	battle.call("_enemy_turn", run)
	_check(int(player.get("current_spirit", 0)) == 33, "enemy multi attack consumes block across hits")

	run = run_session.create_new_run("tester", true)
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	var enemies_before := int(battle.battle_state.get("enemies", []).size())
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "spawn", "enemy_id": "enemy_process_specialist", "amount": 1, "max_allies": 3 }
	battle.call("_enemy_turn", run)
	_check(int(battle.battle_state.get("enemies", []).size()) == enemies_before + 1, "enemy spawn adds combatant")
	_check(String(battle.battle_state["enemies"][1].get("enemy_def_id", "")) == "enemy_process_specialist", "spawned enemy uses requested def")
	_check(not battle.battle_state["enemies"][1].get("intent", {}).is_empty(), "spawned enemy receives an intent")

	run = run_session.create_new_run("algorithm", true)
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	player = battle.battle_state.get("player", {})
	player["discard_pile"] = []
	player["status_list"] = { "service_online": 1, "style_layer": 2, "anxiety": 1 }
	player["class_resource_state"] = { "compute": 3, "complexity": 2 }
	battle.battle_state["enemies"][0]["intent"] = { "intent_type": "cleanse_player", "amount": 2, "card_id": "card_status_meeting_minutes" }
	battle.call("_enemy_turn", run)
	_check(not player.get("status_list", {}).has("service_online"), "enemy cleanse removes player positive status")
	_check(player.get("status_list", {}).has("anxiety"), "enemy cleanse keeps player debuff")
	_check(int(player.get("class_resource_state", {}).get("compute", 0)) == 1, "enemy cleanse reduces player resources")
	_check(_count_card(player.get("discard_pile", []), "card_status_meeting_minutes") == 1, "enemy cleanse can add pollution")

	run = run_session.create_new_run("product_manager", true)
	battle = _start_first_battle(run, content, map, executor)
	_isolate_first_enemy(battle)
	var enemy: Dictionary = battle.battle_state["enemies"][0]
	enemy["current_block"] = 0
	enemy["status_list"] = { "weak": 1, "vulnerable": 1 }
	enemy["intent"] = { "intent_type": "phase_shift", "amount": 5 }
	battle.call("_enemy_turn", run)
	_check(int(enemy.get("phase_index", 0)) == 1, "enemy phase shift increments phase")
	_check(int(enemy.get("current_block", 0)) == 5, "enemy phase shift grants block")
	_check(int(enemy.get("status_list", {}).get("weak", 0)) == 0, "enemy short status decays after action")

func _validate_enemy_phase_scripts(config, content, map, meta) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)

	var run := run_session.create_new_run("backend")
	run["current_floor"] = 6
	var boss_node := { "id": "test_boss_ch1", "node_type": "boss", "floor": 6 }
	var battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, boss_node)
	var boss: Dictionary = battle.battle_state.get("enemies", [])[0]
	var player: Dictionary = battle.battle_state.get("player", {})
	player["hand"] = []
	boss["current_hp"] = 70
	boss["current_block"] = 0
	battle.call("_check_enemy_phase_triggers", run)
	_check(int(boss.get("phase_index", 0)) == 1, "boss phase threshold advances phase")
	_check(_count_card(player.get("hand", []), "card_status_option_promise") == 1, "boss phase pollutes hand")
	_check(int(boss.get("current_block", 0)) >= 10, "boss phase grants block")
	battle.call("_check_enemy_phase_triggers", run)
	_check(_count_card(player.get("hand", []), "card_status_option_promise") == 1, "boss phase triggers only once")
	boss["current_hp"] = 35
	battle.call("_check_enemy_phase_triggers", run)
	_check(_count_card(player.get("draw_pile", []), "card_curse_next_year_promotion") == 1, "boss second phase pollutes draw pile")
	_check(String(boss.get("intent", {}).get("intent_type", "")) == "attack", "boss second phase forces intent")
	_check(int(boss.get("intent", {}).get("amount", 0)) == 18, "boss forced intent keeps configured amount")

	run = run_session.create_new_run("algorithm", true)
	run["current_chapter"] = 3
	run["current_floor"] = 18
	var ceo_node := { "id": "test_boss_ch3", "node_type": "boss", "floor": 18 }
	battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, ceo_node)
	var ceo: Dictionary = battle.battle_state.get("enemies", [])[0]
	var enemies_before := int(battle.battle_state.get("enemies", []).size())
	ceo["current_hp"] = 120
	battle.call("_check_enemy_phase_triggers", run)
	_check(int(battle.battle_state.get("enemies", []).size()) == enemies_before + 1, "ceo phase summons meeting enemy")
	_check(int(ceo.get("current_block", 0)) >= 12, "ceo phase grants block")

	run = run_session.create_new_run("tester", true)
	battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	var elite: Dictionary = battle.call("_build_enemy", "elite_outsource_manager")
	battle.battle_state = {
		"player": {
			"current_spirit": 72,
			"current_block": 0,
			"status_list": {},
			"class_resource_state": {},
			"discard_pile": [],
			"draw_pile": [],
			"hand": [],
		},
		"enemies": [elite],
		"phase": "player",
		"log": [],
	}
	elite["current_hp"] = 40
	var elite_count_before := int(battle.battle_state.get("enemies", []).size())
	battle.call("_check_enemy_phase_triggers", run)
	_check(int(battle.battle_state.get("enemies", []).size()) == elite_count_before + 1, "elite phase can summon support")
	_check(int(elite.get("current_block", 0)) >= 8, "elite phase grants block")

func _validate_map_constraints(run: Dictionary, label: String) -> void:
	var floors: Array = run.get("map_state", {}).get("floors", [])
	var node_graph: Dictionary = run.get("map_state", {}).get("node_graph", {})
	var has_shop := false
	var has_rest := false
	var boss_count := 0
	var node_count := 0
	for layer in floors:
		for node in layer:
			node_count += 1
			has_shop = has_shop or node.get("node_type", "") == "shop"
			has_rest = has_rest or node.get("node_type", "") == "rest"
			boss_count += 1 if node.get("node_type", "") == "boss" else 0
			_check(node_graph.has(String(node.get("id", ""))), "%s node graph contains %s" % [label, node.get("id", "")])
			for next_id in node.get("next_ids", []):
				_check(node_graph.has(String(next_id)), "%s node graph resolves edge %s" % [label, next_id])
	_check(has_shop, "%s includes shop" % label)
	_check(has_rest, "%s includes rest" % label)
	_check(boss_count == 1, "%s has one boss" % label)
	_check(node_graph.size() == node_count, "%s node graph matches floor nodes" % label)
	for node_id in run.get("map_state", {}).get("available_next_nodes", []):
		_check(node_graph.has(String(node_id)), "%s node graph resolves available node" % label)
	_check(node_graph.has(String(run.get("map_state", {}).get("boss_node_id", ""))), "%s node graph resolves boss" % label)

func _validate_shop_event_rest(config, content, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	reward_service.prepare_shop_stock(run)
	_check(run.get("shop_state", {}).get("card_stock", []).size() > 0, "shop has card stock")
	_check(run.get("shop_state", {}).get("relic_stock", []).size() > 0, "shop has relic stock")
	run["currency_perf_points"] = 500
	var card_id := String(run["shop_state"]["card_stock"][0])
	var relic_id := String(run["shop_state"]["relic_stock"][0])
	var deck_before := int(run["deck_state"]["master_deck"].size())
	var relic_before := int(run["owned_relic_ids"].size())
	_check(reward_service.buy_shop_card(run, card_id), "shop card purchase succeeds")
	_check(int(run["deck_state"]["master_deck"].size()) == deck_before + 1, "shop card added")
	_check(reward_service.buy_shop_relic(run, relic_id), "shop relic purchase succeeds")
	_check(int(run["owned_relic_ids"].size()) == relic_before + 1, "shop relic added")
	_check(reward_service.remove_shop_card(run), "shop remove succeeds")
	_check(int(run["deck_state"]["removed_cards"].size()) == 1, "shop remove records card")

	run = run_session.create_new_run("backend")
	run["currency_perf_points"] = 200
	reward_service.prepare_shop_stock(run)
	var target_card_id := String(run["deck_state"]["master_deck"][0])
	var target_count_before := _count_card(run["deck_state"]["master_deck"], target_card_id)
	var currency_before_remove := int(run.get("currency_perf_points", 0))
	var targeted_remove_cost: int = reward_service.remove_cost(run)
	_check(reward_service.remove_shop_card(run, target_card_id), "shop targeted remove succeeds")
	_check(_count_card(run["deck_state"]["master_deck"], target_card_id) == target_count_before - 1, "shop targeted remove removes selected card")
	_check(run["deck_state"]["removed_cards"].has(target_card_id), "shop targeted remove records selected card")
	_check(int(run.get("currency_perf_points", 0)) == currency_before_remove - targeted_remove_cost, "shop targeted remove charges cost")
	_check(not reward_service.remove_shop_card(run, target_card_id), "shop second remove is blocked")

	run = run_session.create_new_run("backend")
	run["currency_perf_points"] = 200
	reward_service.prepare_shop_stock(run)
	currency_before_remove = int(run.get("currency_perf_points", 0))
	_check(not reward_service.remove_shop_card(run, "card_missing_for_test"), "shop missing card remove fails")
	_check(int(run.get("currency_perf_points", 0)) == currency_before_remove, "shop missing card remove does not charge")
	_check(not bool(run.get("shop_state", {}).get("removed", false)), "shop missing card remove keeps remove available")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	run["currency_perf_points"] = 100
	reward_service.prepare_shop_stock(run)
	_check(not run.get("shop_state", {}).get("relic_stock", []).has("relic_blue_light_glasses"), "shop stock excludes owned relics")
	var refresh_cost: int = reward_service.shop_refresh_cost(run)
	var currency_before_refresh := int(run.get("currency_perf_points", 0))
	_check(reward_service.refresh_shop_stock(run), "shop refresh succeeds")
	_check(int(run.get("currency_perf_points", 0)) == currency_before_refresh - refresh_cost, "shop refresh charges configured cost")
	_check(int(run.get("shop_state", {}).get("refresh_count", 0)) == 1, "shop refresh increments counter")
	_check(run.get("shop_state", {}).get("card_stock", []).size() > 0, "shop refresh keeps card stock")
	_check(not run.get("shop_state", {}).get("relic_stock", []).has("relic_blue_light_glasses"), "shop refresh keeps owned relics out")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_employee_coupon")
	run["currency_perf_points"] = 200
	reward_service.prepare_shop_stock(run)
	var discounted_card_cost: int = reward_service.card_cost(run)
	_check(reward_service.refresh_shop_stock(run), "shop refresh with discount relic succeeds")
	_check(reward_service.card_cost(run) == discounted_card_cost, "shop refresh does not consume first purchase discount")
	_check(reward_service.remove_shop_card(run), "shop remove after refresh succeeds")
	_check(bool(run.get("shop_state", {}).get("removed", false)), "shop remove flag set before refresh")
	_check(reward_service.refresh_shop_stock(run), "shop refresh after remove succeeds")
	_check(bool(run.get("shop_state", {}).get("removed", false)), "shop refresh preserves remove flag")

	run = run_session.create_new_run("backend")
	reward_service.prepare_event(run)
	_check(not reward_service.current_event(run).is_empty(), "event prepared")
	var history_before := int(run.get("event_history_ids", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("event_history_ids", []).size()) == history_before + 1, "event history recorded")
	_check(run.get("event_state", {}).is_empty(), "event state cleared")
	_validate_event_effect_resolution(config, content, map, meta, reward_service)

	run = run_session.create_new_run("backend")
	var ps: Dictionary = run.get("player_state", {})
	ps["current_spirit"] = 10
	run["player_state"] = ps
	var rest_id := _first_node_of_type(run, "rest")
	run["current_node_id"] = rest_id
	reward_service.rest_recover(run)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) > 10, "rest recover increases spirit")
	_check(String(run.get("current_node_id", "")) == "", "rest recover clears completed node")
	run = run_session.create_new_run("backend")
	rest_id = _first_node_of_type(run, "rest")
	run["current_node_id"] = rest_id
	reward_service.rest_upgrade(run)
	_check(int(run.get("deck_state", {}).get("upgraded_cards", []).size()) == 1, "rest upgrade records card")
	_check(String(run.get("current_node_id", "")) == "", "rest upgrade clears completed node")
	run = run_session.create_new_run("backend")
	rest_id = _first_node_of_type(run, "rest")
	run["current_node_id"] = rest_id
	reward_service.rest_upgrade_card(run, "card_backend_publish_script")
	_check(run.get("deck_state", {}).get("upgraded_cards", []).has("card_backend_publish_script"), "rest selected upgrade records chosen card")
	_check(String(run.get("current_node_id", "")) == "", "rest selected upgrade clears completed node")

func _validate_event_effect_resolution(config, content, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)

	var run := run_session.create_new_run("backend")
	run["event_state"] = { "event_id": "event_unlocked_office" }
	var currency_before := int(run.get("currency_perf_points", 0))
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("currency_perf_points", 0)) == currency_before + 45, "event gain currency applies")

	run = run_session.create_new_run("backend")
	run["deck_state"]["upgraded_cards"] = ["card_backend_interface_probe"]
	run["event_state"] = { "event_id": "event_unlocked_office" }
	reward_service.choose_event_option(run, 1)
	_check(int(run.get("deck_state", {}).get("upgraded_cards", []).size()) == 2, "event upgrade skips already upgraded card")
	_check(run.get("deck_state", {}).get("upgraded_cards", []).has("card_backend_circuit_breaker"), "event upgrade records next eligible card")

	run = run_session.create_new_run("backend")
	run["event_state"] = { "event_id": "event_wrong_email" }
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "event draw card adds run card outside battle")

	run = run_session.create_new_run("backend")
	var ps: Dictionary = run.get("player_state", {})
	ps["current_spirit"] = 20
	run["player_state"] = ps
	run["event_state"] = { "event_id": "event_pantry_gossip" }
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == 32, "event recover spirit applies")

	run = run_session.create_new_run("backend")
	run["event_state"] = { "event_id": "event_pantry_gossip" }
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 1)
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before - 1, "event remove card shrinks deck")
	_check(int(run.get("deck_state", {}).get("removed_cards", []).size()) == 1, "event remove card records removal")

	run = run_session.create_new_run("backend")
	run["currency_perf_points"] = 10
	run["event_state"] = { "event_id": "event_vending_bug" }
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("currency_perf_points", 0)) == 0, "event negative currency clamps at zero")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "event add random card applies")

	run = run_session.create_new_run("backend")
	ps = run.get("player_state", {})
	ps["current_spirit"] = 30
	run["player_state"] = ps
	run["event_state"] = { "event_id": "event_intern_blame" }
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.choose_event_option(run, 0)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == 22, "event lose spirit applies")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "event combined add card applies")

	run = run_session.create_new_run("backend")
	run["event_state"] = { "event_id": "event_private_talk" }
	var relic_before := int(run.get("owned_relic_ids", []).size())
	reward_service.choose_event_option(run, 1)
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before + 1, "event add random relic applies")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "event relic reward avoids duplicates")

func _validate_reward_economy(config, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_parking_pass")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": [],
		"currency_amount": 10,
		"source_node_type": "elite_battle",
	}
	reward_service.accept_battle_reward(run, "")
	_check(int(run.get("currency_perf_points", 0)) == 25, "parking pass adds elite currency")
	_check(int(run.get("run_counters", {}).get("elite_wins", 0)) == 1, "elite reward increments counter")

	run = run_session.create_new_run("backend")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_blue_light_glasses", "relic_lumbar_cushion"],
		"currency_amount": 11,
		"source_node_type": "elite_battle",
	}
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	var relic_before := int(run.get("owned_relic_ids", []).size())
	reward_service.accept_battle_reward(run, "card_backend_interface_probe", "relic_blue_light_glasses")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 1, "reward selected card added")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before + 1, "reward selected relic added")
	_check(run.get("owned_relic_ids", []).has("relic_blue_light_glasses"), "reward chosen relic id added")
	_check(run.get("pending_reward_state", {}).is_empty(), "reward selection clears pending reward")

	run = run_session.create_new_run("backend")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_blue_light_glasses"],
		"currency_amount": 7,
		"source_node_type": "elite_battle",
	}
	relic_before = int(run.get("owned_relic_ids", []).size())
	reward_service.accept_battle_reward(run, "", "")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before, "reward can skip relic")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_blue_light_glasses"],
		"currency_amount": 7,
		"source_node_type": "elite_battle",
	}
	deck_before = int(run.get("deck_state", {}).get("master_deck", []).size())
	reward_service.accept_battle_reward(run, "card_frontend_pixel_tap", "relic_blue_light_glasses")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before, "reward ignores non-candidate card")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "reward ignores duplicate relic")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_employee_coupon")
	run["currency_perf_points"] = 100
	reward_service.prepare_shop_stock(run)
	var before_currency := int(run.get("currency_perf_points", 0))
	var card_id := String(run["shop_state"]["card_stock"][0])
	var cost: int = int(reward_service.card_cost(run))
	_check(cost < RewardService.CARD_COST, "employee coupon discounts first shop purchase")
	reward_service.buy_shop_card(run, card_id)
	_check(int(run.get("currency_perf_points", 0)) == before_currency - cost, "discounted card cost charged")
	_check(reward_service.card_cost(run) == RewardService.CARD_COST, "shop discount consumed")


func _validate_initial_boosts(config, content, map, meta, reward_service, save) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	var pending: Dictionary = reward_service.prepare_initial_boosts(run)
	var candidates: Array = pending.get("candidate_boost_ids", [])
	_check(candidates.size() == 3, "initial boost rolls three candidates")
	_check(_array_has_no_duplicates(candidates), "initial boost candidates are unique")
	_check(String(run.get("current_scene_tag", "")) == "initial_boost", "initial boost prepare stores scene tag")
	var rerolled: Dictionary = reward_service.prepare_initial_boosts(run)
	_check(rerolled.get("candidate_boost_ids", []) == candidates, "initial boost prepare does not reroll pending candidates")
	save.save_suspend(run, meta.meta_state)
	var restored = RunSessionScript.new()
	restored.call("setup", config, map, meta)
	_check(restored.restore_from_suspend(save.load_suspend()), "initial boost suspend restore succeeds")
	_check(restored.run_state.get("pending_initial_boost_state", {}).get("candidate_boost_ids", []) == candidates, "initial boost suspend keeps candidates")
	save.clear_suspend()

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_perf_points_99"] }
	_check(reward_service.accept_initial_boost(run, "boost_perf_points_99"), "initial boost currency accepted")
	_check(int(run.get("currency_perf_points", 0)) == 99, "initial boost currency applies")
	_check(String(run.get("selected_initial_boost_id", "")) == "boost_perf_points_99", "initial boost selection recorded")
	_check(run.get("pending_initial_boost_state", {}).is_empty(), "initial boost pending clears after accept")
	_check(String(run.get("current_scene_tag", "")) == "map", "initial boost accept returns to map")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_random_cards_2"] }
	var deck_before := int(run.get("deck_state", {}).get("master_deck", []).size())
	_check(reward_service.accept_initial_boost(run, "boost_random_cards_2"), "initial boost random cards accepted")
	_check(int(run.get("deck_state", {}).get("master_deck", []).size()) == deck_before + 2, "initial boost random cards added")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_random_relic_1"] }
	var relic_before := int(run.get("owned_relic_ids", []).size())
	_check(reward_service.accept_initial_boost(run, "boost_random_relic_1"), "initial boost random relic accepted")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before + 1, "initial boost random relic added")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "initial boost random relic avoids duplicates")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_opening_draw_1"] }
	var draw_before := int(run.get("player_state", {}).get("opening_draw_bonus", 0))
	_check(reward_service.accept_initial_boost(run, "boost_opening_draw_1"), "initial boost opening draw accepted")
	_check(int(run.get("player_state", {}).get("opening_draw_bonus", 0)) == draw_before + 1, "initial boost opening draw applies")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_opening_block_6"] }
	var block_before := int(run.get("player_state", {}).get("opening_block_bonus", 0))
	_check(reward_service.accept_initial_boost(run, "boost_opening_block_6"), "initial boost opening block accepted")
	_check(int(run.get("player_state", {}).get("opening_block_bonus", 0)) == block_before + 6, "initial boost opening block applies")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_max_spirit_8"] }
	var max_before := int(run.get("player_state", {}).get("max_spirit", 0))
	var spirit_before := int(run.get("player_state", {}).get("current_spirit", 0))
	_check(reward_service.accept_initial_boost(run, "boost_max_spirit_8"), "initial boost max spirit accepted")
	_check(int(run.get("player_state", {}).get("max_spirit", 0)) == max_before + 8, "initial boost max spirit applies")
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == spirit_before + 8, "initial boost spirit heal applies")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_blue_light_glasses"] }
	relic_before = int(run.get("owned_relic_ids", []).size())
	_check(reward_service.accept_initial_boost(run, "boost_blue_light_glasses"), "initial boost explicit relic accepted")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before + 1, "initial boost explicit relic added")
	_check(run.get("owned_relic_ids", []).has("relic_blue_light_glasses"), "initial boost explicit relic id added")

	run = run_session.create_new_run("backend")
	run["owned_relic_ids"].append("relic_blue_light_glasses")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_blue_light_glasses"] }
	relic_before = int(run.get("owned_relic_ids", []).size())
	_check(reward_service.accept_initial_boost(run, "boost_blue_light_glasses"), "initial boost duplicate explicit relic accepted")
	_check(int(run.get("owned_relic_ids", []).size()) == relic_before, "initial boost duplicate explicit relic ignored")
	_check(_array_has_no_duplicates(run.get("owned_relic_ids", [])), "initial boost explicit relic avoids duplicates")

	run = run_session.create_new_run("backend")
	run["pending_initial_boost_state"] = { "candidate_boost_ids": ["boost_perf_points_99"] }
	_check(not reward_service.accept_initial_boost(run, "boost_employee_coupon"), "initial boost rejects non-candidate id")
	_check(int(run.get("currency_perf_points", 0)) == 0, "initial boost non-candidate does not apply")
	_check(String(run.get("selected_initial_boost_id", "")).is_empty(), "initial boost non-candidate not recorded")

func _validate_save_roundtrip(config, map, meta, save) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	run["current_scene_tag"] = "map"
	save.save_suspend(run, meta.meta_state)
	_check(save.has_suspend(), "suspend save exists")
	_check(not save.load_suspend().get("serialized_meta_state_snapshot", {}).is_empty(), "suspend stores meta snapshot")
	var restored_session = RunSessionScript.new()
	restored_session.call("setup", config, map, meta)
	_check(restored_session.restore_from_suspend(save.load_suspend()), "suspend restore succeeds")
	_check(restored_session.run_state.get("selected_class_id", "") == "backend", "suspend selected class roundtrip")
	var mismatched_suspend: Dictionary = save.load_suspend().duplicate(true)
	var mismatched_run: Dictionary = mismatched_suspend.get("serialized_run_state", {}).duplicate(true)
	mismatched_suspend["scene_tag"] = "shop"
	mismatched_run["current_scene_tag"] = "map"
	mismatched_suspend["serialized_run_state"] = mismatched_run
	var scene_tag_session = RunSessionScript.new()
	scene_tag_session.call("setup", config, map, meta)
	_check(scene_tag_session.restore_from_suspend(mismatched_suspend), "mismatched suspend restore succeeds")
	_check(String(scene_tag_session.run_state.get("current_scene_tag", "")) == "shop", "suspend top-level scene tag wins on restore")
	save.clear_suspend()
	run["map_state"]["node_graph"] = {}
	var first_available_node_id := String(run.get("map_state", {}).get("available_next_nodes", [])[0])
	_check(not map.find_node(run, first_available_node_id).is_empty(), "map node graph rebuild finds available node")
	_check(not run.get("map_state", {}).get("node_graph", {}).is_empty(), "map node graph rebuild persists index")

	run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var content = ContentResolverScript.new()
	content.call("setup", config)
	var reward_service = RewardServiceScript.new()
	reward_service.call("setup", content, map, meta)
	var executor = EffectExecutorScript.new()
	executor.call("setup", config)
	run = run_session.create_new_run("backend")
	var battle = _start_first_battle(run, content, map, executor)
	run["current_scene_tag"] = "battle"
	battle.battle_state["player"]["current_energy"] = 1
	battle.battle_state["log"].append("battle_roundtrip_marker")
	var enemies_for_selection: Array = battle.battle_state.get("enemies", [])
	if enemies_for_selection.size() == 1:
		var duplicate_enemy: Dictionary = enemies_for_selection[0].duplicate(true)
		duplicate_enemy["name"] = "恢复目标"
		duplicate_enemy["current_hp"] = max(1, int(duplicate_enemy.get("current_hp", 1)))
		enemies_for_selection.append(duplicate_enemy)
		battle.battle_state["enemies"] = enemies_for_selection
	if enemies_for_selection.size() > 1:
		battle.select_target(1)
	battle.persist_current_battle(run)
	save.save_suspend(run, meta.meta_state)
	var battle_save: Dictionary = save.load_suspend()
	_check(String(battle_save.get("scene_tag", "")) == "battle", "battle suspend scene tag stored")
	var restored_battle_session = RunSessionScript.new()
	restored_battle_session.call("setup", config, map, meta)
	_check(restored_battle_session.restore_from_suspend(battle_save), "battle suspend run restore succeeds")
	var restored_battle = BattleServiceScript.new()
	restored_battle.call("setup", content, executor)
	_check(restored_battle.restore_battle(restored_battle_session.run_state), "battle suspend restores battle service")
	_check(int(restored_battle.battle_state.get("player", {}).get("current_energy", 0)) == 1, "battle suspend restores player energy")
	_check(restored_battle.battle_state.get("log", []).has("battle_roundtrip_marker"), "battle suspend restores battle log")
	_check(int(restored_battle.battle_state.get("enemies", []).size()) >= 2, "battle suspend restores battle enemies")
	_check(restored_battle.selected_target_index() == 1, "battle suspend restores selected target")
	save.clear_suspend()

	run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	run = run_session.create_new_run("backend")
	run["current_scene_tag"] = "reward"
	run["pending_reward_state"] = {
		"candidate_card_ids": ["card_backend_interface_probe"],
		"candidate_relic_ids": ["relic_lumbar_cushion"],
		"currency_amount": 12,
		"source_node_type": "normal_battle",
	}
	save.save_suspend(run, meta.meta_state)
	var reward_save: Dictionary = save.load_suspend()
	_check(String(reward_save.get("scene_tag", "")) == "reward", "reward suspend scene tag stored")
	_check(reward_save.get("serialized_run_state", {}).get("pending_reward_state", {}).get("candidate_card_ids", []).has("card_backend_interface_probe"), "reward suspend keeps card candidates")
	_check(reward_save.get("serialized_run_state", {}).get("pending_reward_state", {}).get("candidate_relic_ids", []).has("relic_lumbar_cushion"), "reward suspend keeps relic candidates")
	save.clear_suspend()

	run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	run = run_session.create_new_run("backend")
	run["current_scene_tag"] = "event"
	reward_service.prepare_event(run)
	var prepared_event_id := String(run.get("event_state", {}).get("event_id", ""))
	save.save_suspend(run, meta.meta_state)
	var event_save: Dictionary = save.load_suspend()
	_check(String(event_save.get("scene_tag", "")) == "event", "event suspend scene tag stored")
	_check(String(event_save.get("serialized_run_state", {}).get("event_state", {}).get("event_id", "")) == prepared_event_id, "event suspend keeps prepared event")
	save.clear_suspend()

	run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	run = run_session.create_new_run("backend")
	run["current_scene_tag"] = "shop"
	run["currency_perf_points"] = 500
	reward_service.prepare_shop_stock(run)
	var shop_card_id := String(run.get("shop_state", {}).get("card_stock", [])[0])
	var shop_stock_before: Array = run.get("shop_state", {}).get("card_stock", []).duplicate(true)
	save.save_suspend(run, meta.meta_state)
	var shop_save: Dictionary = save.load_suspend()
	_check(String(shop_save.get("scene_tag", "")) == "shop", "shop suspend scene tag stored")
	_check(shop_save.get("serialized_run_state", {}).get("shop_state", {}).get("card_stock", []) == shop_stock_before, "shop suspend keeps rolled stock")
	reward_service.buy_shop_card(run, shop_card_id)
	save.save_suspend(run, meta.meta_state)
	shop_save = save.load_suspend()
	_check(shop_save.get("serialized_run_state", {}).get("deck_state", {}).get("master_deck", []).has(shop_card_id), "shop suspend keeps purchased card")
	_check(not shop_save.get("serialized_run_state", {}).get("shop_state", {}).get("card_stock", []).has(shop_card_id), "shop suspend removes purchased stock")
	reward_service.refresh_shop_stock(run)
	save.save_suspend(run, meta.meta_state)
	shop_save = save.load_suspend()
	_check(int(shop_save.get("serialized_run_state", {}).get("shop_state", {}).get("refresh_count", 0)) == 1, "shop suspend keeps refresh count")
	save.clear_suspend()

	run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	run = run_session.create_new_run("backend")
	run["current_scene_tag"] = "rest"
	run["player_state"]["current_spirit"] = 37
	save.save_suspend(run, meta.meta_state)
	var rest_save: Dictionary = save.load_suspend()
	_check(String(rest_save.get("scene_tag", "")) == "rest", "rest suspend scene tag stored")
	_check(int(rest_save.get("serialized_run_state", {}).get("player_state", {}).get("current_spirit", 0)) == 37, "rest suspend keeps player spirit")
	save.clear_suspend()

func _validate_meta_settlement(config, map, meta) -> void:
	meta.meta_state = meta.default_meta_state()
	var backend_class: Dictionary = config.get_def("classes", "backend")
	var tester_class: Dictionary = config.get_def("classes", "tester")
	var hr_class: Dictionary = config.get_def("classes", "hr")
	var default_settings: Dictionary = meta.default_meta_state().get("settings", {})
	_check(default_settings.get("master_volume", 0) == 100, "meta default settings include master volume")
	_check(not bool(default_settings.get("fullscreen", true)), "meta default settings include fullscreen")
	_check(not bool(default_settings.get("reduce_motion", true)), "meta default settings include reduce motion")
	_check(bool(default_settings.get("ambient_motion", false)), "meta default settings include ambient motion")
	_check(not bool(default_settings.get("screen_shake", true)), "meta default settings include screen shake")
	meta.update_setting("master_volume", 42)
	meta.update_setting("fullscreen", true)
	meta.update_setting("reduce_motion", true)
	_check(int(meta.meta_state.get("settings", {}).get("master_volume", 0)) == 42, "meta settings store master volume")
	_check(bool(meta.meta_state.get("settings", {}).get("fullscreen", false)), "meta settings store fullscreen")
	_check(bool(meta.meta_state.get("settings", {}).get("reduce_motion", false)), "meta settings store reduce motion")
	meta.update_setting("master_volume", 100)
	meta.update_setting("fullscreen", false)
	_check(meta.is_class_playable("backend"), "meta marks backend playable")
	_check(not meta.is_class_playable("product_manager"), "meta keeps product manager locked as placeholder")
	_check(not meta.is_class_playable("hr"), "meta keeps hr out of playable classes")
	_check(meta.class_availability_label(backend_class) == "可出战", "career tree labels playable class")
	_check(meta.class_availability_label(tester_class) == "锁定占位", "career tree labels locked office placeholder")
	_check(meta.class_availability_label(hr_class) == "扩展占位", "career tree labels locked hr placeholder")
	_check(meta.class_unlock_label(hr_class).contains("扩展预留"), "career tree explains hr placeholder")
	_check(meta.class_unlock_progress(tester_class) == "占位", "career tree reports placeholder progress")
	var meta_scene_source := FileAccess.get_file_as_string("res://Scripts/UI/MetaProgressionScene.gd")
	_check(not meta_scene_source.contains("后端全链路完成后"), "meta scene copy reflects backend chain state")
	meta.meta_state["career_milestones"] = { "elite_wins": 2, "events_resolved": 4, "highest_floor_reached": 12 }
	_check(meta.class_unlock_progress(tester_class) == "占位", "career tree keeps placeholder progress")

	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("tester", true)
	run["current_floor"] = 8
	run["run_counters"]["elite_wins"] = 2
	run["run_counters"]["events_resolved"] = 3
	run["defeated_boss_ids"] = ["boss_pitch_supervisor"]
	var currency_before := int(meta.meta_state.get("owned_discomfort_currency", 0))
	var earned: int = meta.settle_run(run, false)
	_check(earned > 0, "meta settlement earns currency")
	_check(int(meta.meta_state.get("owned_discomfort_currency", 0)) == currency_before + earned, "meta currency increases")
	_check(int(meta.meta_state.get("career_milestones", {}).get("elite_wins", 0)) >= 2, "meta records elite wins")
	_check(meta.meta_state.get("defeated_boss_records", []).has("boss_pitch_supervisor"), "meta records defeated boss")
	_check(int(run.get("settlement_state", {}).get("earned_currency", 0)) == earned, "settlement summary stores earned currency")
	_check(int(run.get("settlement_state", {}).get("highest_floor", 0)) == 8, "settlement summary stores floor")
	_check(int(run.get("settlement_state", {}).get("elite_count", 0)) == 2, "settlement summary stores elites")
	var currency_after := int(meta.meta_state.get("owned_discomfort_currency", 0))
	var earned_again: int = meta.settle_run(run, false)
	_check(earned_again == earned, "settlement returns stable earned amount after settled")
	_check(int(meta.meta_state.get("owned_discomfort_currency", 0)) == currency_after, "settlement is idempotent for currency")

	run = run_session.create_new_run("backend")
	run["current_floor"] = 18
	run["run_flags"]["victory"] = true
	run["defeated_boss_ids"] = ["boss_pitch_supervisor", "boss_mutant_hr", "boss_mutant_ceo"]
	var victory_earned: int = meta.settle_run(run, true)
	_check(victory_earned >= 80, "victory settlement includes victory bonus")
	_check(bool(run.get("settlement_state", {}).get("victory", false)), "settlement summary stores victory")
	_check(int(run.get("settlement_state", {}).get("boss_count", 0)) == 3, "settlement summary stores boss count")

func _validate_meta_upgrades(config, map, meta, reward_service) -> void:
	meta.meta_state = meta.default_meta_state()
	meta.meta_state["owned_discomfort_currency"] = 100
	var chair_cost := int(config.get_def("meta_upgrades", "meta_chair").get("cost_curve", [0])[0])
	_check(meta.buy_upgrade("meta_chair"), "meta upgrade purchase succeeds")
	_check(meta.get_upgrade_level("meta_chair") == 1, "meta upgrade level increases")
	_check(int(meta.meta_state.get("owned_discomfort_currency", 0)) == 100 - chair_cost, "meta upgrade purchase charges currency")
	_check(not meta.buy_upgrade("unlock_hr"), "career unlock cannot be bought as workstation upgrade")

	meta.meta_state = meta.default_meta_state()
	meta.meta_state["meta_upgrade_levels"] = {
		"meta_chair": 2,
		"meta_privacy_screen": 3,
		"meta_coffee_beans": 2,
		"meta_hard_drive": 2,
	}
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	var ps: Dictionary = run.get("player_state", {})
	_check(int(ps.get("max_spirit", 0)) == 80, "meta chair raises run max spirit")
	_check(int(ps.get("current_spirit", 0)) == 80, "meta chair raises run current spirit")
	_check(int(ps.get("base_energy", 0)) == 4, "meta coffee beans raises base energy at max level")
	_check(int(ps.get("opening_block_bonus", 0)) == 6, "meta privacy screen grants opening block bonus")
	_check(int(ps.get("opening_draw_bonus", 0)) == 2, "meta hard drive grants opening draw bonus")

	meta.meta_state = meta.default_meta_state()
	meta.meta_state["meta_upgrade_levels"] = { "meta_nap_bed": 3 }
	run = run_session.create_new_run("backend")
	ps = run.get("player_state", {})
	ps["max_spirit"] = 100
	ps["current_spirit"] = 40
	run["player_state"] = ps
	run["current_node_id"] = _first_node_of_type(run, "rest")
	reward_service.rest_recover(run)
	_check(int(run.get("player_state", {}).get("current_spirit", 0)) == 82, "meta nap bed increases rest recovery")

	meta.meta_state = meta.default_meta_state()
	meta.meta_state["meta_upgrade_levels"] = { "meta_canteen_card": 2 }
	run = run_session.create_new_run("backend")
	run["currency_perf_points"] = 100
	reward_service.prepare_shop_stock(run)
	var card_id := String(run.get("shop_state", {}).get("card_stock", [])[0])
	var discounted_cost: int = reward_service.card_cost(run)
	_check(discounted_cost == RewardService.CARD_COST - 10, "meta canteen card discounts first shop purchase")
	reward_service.buy_shop_card(run, card_id)
	_check(int(run.get("currency_perf_points", 0)) == 100 - discounted_cost, "meta canteen card discounted purchase charges correctly")
	_check(reward_service.card_cost(run) == RewardService.CARD_COST, "meta canteen card discount is consumed")
	meta.meta_state = meta.default_meta_state()

func _validate_boss_progression(config, map, meta, reward_service) -> void:
	var run_session = RunSessionScript.new()
	run_session.call("setup", config, map, meta)
	var run := run_session.create_new_run("backend")
	run["current_node_id"] = String(run.get("map_state", {}).get("boss_node_id", ""))
	var result: String = map.complete_current_node(run)
	_check(result == "next_chapter", "chapter 1 boss advances chapter")
	_check(int(run.get("current_chapter", 0)) == 2, "chapter index is 2 after boss")
	_check(int(run.get("current_floor", 0)) == 7, "chapter 2 map starts on floor 7 after boss")
	_check(String(run.get("current_node_id", "")) == "", "chapter boss clears completed node")
	map.generate_chapter(run, 3)
	run["current_node_id"] = String(run.get("map_state", {}).get("boss_node_id", ""))
	result = map.complete_current_node(run)
	_check(result == "run_victory", "chapter 3 boss yields run victory")
	_check(int(run.get("current_floor", 0)) == 18, "chapter 3 boss completion records top floor")
	_check(String(run.get("current_node_id", "")) == "", "final boss clears completed node")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK: %s" % label)
	else:
		push_error("FAIL: %s" % label)
		failed = true

func _first_node_of_type(run: Dictionary, node_type: String) -> String:
	for layer in run.get("map_state", {}).get("floors", []):
		for node in layer:
			if node.get("node_type", "") == node_type:
				return String(node.get("id", ""))
	return ""

func _start_first_battle(run: Dictionary, content, map, executor):
	var first_node_id := String(run.get("map_state", {}).get("available_next_nodes", [])[0])
	var node: Dictionary = map.choose_node(run, first_node_id)
	var battle = BattleServiceScript.new()
	battle.call("setup", content, executor)
	battle.start_battle(run, node)
	return battle

func _isolate_first_enemy(battle) -> void:
	var enemies: Array = battle.battle_state.get("enemies", [])
	if enemies.is_empty():
		return
	battle.battle_state["enemies"] = [enemies[0]]

func _count_card(pile: Array, card_id: String) -> int:
	var count := 0
	for item in pile:
		if String(item) == card_id:
			count += 1
	return count

func _has_intent_type(entries: Array, intent_type: String) -> bool:
	for entry in entries:
		if String(entry.get("intent_type", "")) == intent_type:
			return true
	return false

func _array_has_no_duplicates(values: Array) -> bool:
	var seen := {}
	for value in values:
		var key := String(value)
		if seen.has(key):
			return false
		seen[key] = true
	return true
