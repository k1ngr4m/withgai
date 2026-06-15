extends Control

func _ready() -> void:
	UiFactory.fill(self)
	AppRoot.boot()
	AppRoot.flow_controller.set_root(self)
	AppRoot.flow_controller.show_scene("main_menu")
