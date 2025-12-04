class_name PlayerSpawner
extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player
	

func spawn_player(player_data: Dictionary) -> Node2D:
	@warning_ignore("unsafe_cast")
	var client_data: Dictionary = player_data.client_data
	
	var player: Node = init_player(client_data)
		
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	
	@warning_ignore("unsafe_cast")
	save_component.push_save_bytes(player_data.save as PackedByteArray)
	
	return player

@rpc("any_peer", "call_remote")
func request_spawn_player(client_data: Dictionary) -> void:
	var player: Node = init_player(client_data)
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	
	var load_error: Error = save_component.load_state()
	assert(load_error == OK or load_error == ERR_FILE_NOT_FOUND, 
		"Something failed while trying to load player. 
		Error: %s." % error_string(load_error))
	
	var player_data: Dictionary = {
		save=save_component.save_container.serialize(),
		client_data=client_data
	}
	
	spawn(player_data)

func init_player(client_data: Dictionary) -> Node:
	assert(client_data.peer_id)
	assert(client_data.username)
	assert(client_data.scene)
	
	@warning_ignore("unsafe_cast")
	var peer_id: int = client_data.peer_id as int
	@warning_ignore("unsafe_cast")
	var scene_path: String = client_data.scene
	
	var scene: PackedScene = load(scene_path)
	var player: Node = scene.instantiate()
	player.set_multiplayer_authority(peer_id)
	player.name = str(client_data.username)
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	assert(save_component != null, "Player must have a `SaveComponent`.")
	save_component.instantiate.emit()
	
	return player
