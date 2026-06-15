class_name FlowController
extends RefCounted

const SCENES := {
	"main_menu": "res://Scenes/MainMenuScene.tscn",
	"class_select": "res://Scenes/ClassSelectScene.tscn",
	"map": "res://Scenes/MapScene.tscn",
	"battle": "res://Scenes/BattleScene.tscn",
	"reward": "res://Scenes/RewardScene.tscn",
	"shop": "res://Scenes/ShopScene.tscn",
	"event": "res://Scenes/EventScene.tscn",
	"rest": "res://Scenes/RestScene.tscn",
	"run_result": "res://Scenes/RunResultScene.tscn",
	"meta": "res://Scenes/MetaProgressionScene.tscn",
}

var root: Node
var current_scene: Node

func set_root(p_root: Node) -> void:
	root = p_root

func show_scene(tag: String) -> void:
	if root == null:
		return
	if AppRoot.run_session.has_active_run():
		AppRoot.run_session.run_state["current_scene_tag"] = tag
		if tag != "battle":
			AppRoot.save_service.save_suspend(AppRoot.run_session.run_state, AppRoot.meta_service.meta_state)
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
	var packed: PackedScene = load(SCENES.get(tag, SCENES["main_menu"]))
	current_scene = packed.instantiate()
	root.add_child(current_scene)
