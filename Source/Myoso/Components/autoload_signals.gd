extends Node

signal connected_to_server()

func _ready() -> void:
	Client.connected_to_server.connect(on_connected_to_server)
	
func on_connected_to_server() -> void:
	connected_to_server.emit()
