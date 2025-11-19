class_name PlayerSpawner
extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player

func spawn_player(player_data: Dictionary) -> Node2D:
	var player: Node2D = player_scene.instantiate()
	@warning_ignore("unsafe_cast")
	player.set_multiplayer_authority(player_data.peer_id as int)
	player.name = str(player_data.peer_id)
	
	var client_component: ClientComponent = player.get_node_or_null("%ClientComponent")
	if client_component:
		client_component.spawn_with_data(player_data)
	
	return player

@rpc("any_peer", "call_remote")
func request_spawn(data: Dictionary) -> void:
	spawn(data)
