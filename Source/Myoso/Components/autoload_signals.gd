extends Node

signal connected_to_server()
signal peer_disconnected(peer_id: int)
signal scene_changed()

func _ready() -> void:
	Client.connected_to_server.connect(on_connected_to_server)
	Server.peer_disconnected.connect(on_peer_disconnected)
	get_tree().scene_changed.connect(on_scene_changed)
	
func on_connected_to_server() -> void:
	connected_to_server.emit()

func on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

func on_scene_changed() -> void:
	scene_changed.emit()
