class_name PlayerSpawner
extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player
	

func spawn_player(player_data: Dictionary) -> Node2D:
	var player: Node2D = player_scene.instantiate()

	@warning_ignore("unsafe_cast")
	player.set_multiplayer_authority(player_data.peer_id as int)
	player.name = str(player_data.username)
	
	if get_multiplayer_authority() == 1:
		var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
		assert(save_component != null, "Player must have a `SaveComponent`.")
		var _load_save_error: Error = save_component.load_state()
	
	return player

@rpc("any_peer", "call_remote")
func request_spawn_player(player_data: Dictionary) -> void:
	spawn(player_data)
