class_name AutoloadSignals
extends Node

signal connected_to_server
signal peer_disconnected(peer_id: int)


func _ready() -> void:
	Client.connected_to_server.connect(on_connected_to_server)
	Server.peer_disconnected.connect(on_peer_disconnected)


func on_connected_to_server() -> void:
	connected_to_server.emit()


func on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)
