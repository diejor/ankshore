extends Node

signal scene_changed(node: Node)
signal connected_to_server()

func _ready() -> void:
	GameInstance.scene_manager.scene_changed.connect(on_scene_changed)
	GameInstance.client.connected_to_server.connect(on_connected_to_server)
	
func on_scene_changed(node: Node) -> void:
	scene_changed.emit(node)
	
func on_connected_to_server() -> void:
	connected_to_server.emit()
