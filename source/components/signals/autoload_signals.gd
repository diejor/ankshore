class_name AutoloadSignals
extends Node

signal connected_to_server
signal peer_disconnected(peer_id: int)
signal peer_connected(peer_id: int)

func _ready() -> void:
	Client.connected_to_server.connect(_on_connected_to_server)
	Client.peer_disconnected.connect(_on_peer_disconnected)
	Client.peer_connected.connect(_on_peer_connected)


func _on_connected_to_server() -> void:
	connected_to_server.emit()

func _on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

func _on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)
