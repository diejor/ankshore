class_name Wolf
extends Node

@onready var game_client: GameClient = %GameClient

@onready var controller: CharacterBody2D = $CharacterBody2D

func _enter_tree() -> void:
	owner = $"/root/Winter"

func _ready() -> void:
	owner = get_tree().root
	if game_client:
		game_client.multiplayer_api.connected_to_server.connect(on_connected_to_server)

func on_connected_to_server():
	var player_data = {
		username = game_client.client_username,
		peer_id = game_client.multiplayer_api.get_unique_id(),
		position = controller.position
	}
	
	game_client.player_spawner.request_spawn.rpc_id(1, player_data)
	queue_free()
