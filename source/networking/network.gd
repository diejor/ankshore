extends Node

@export var client_backend: MultiplayerClientBackend
@export var server_backend: MultiplayerServerBackend

func _ready() -> void:
	Client.backend = client_backend
	Server.backend = server_backend
