class_name PlayerSpawner
extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player
	

func spawn_player(player_data: Dictionary) -> Node2D:
	var client_data: Dictionary = player_data.client_data
	var player: Node = ClientComponent.instantiate(client_data)
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	save_component.deserialize(player_data.save as PackedByteArray)
	
	return player


@rpc("any_peer", "call_remote", "reliable")
func request_spawn_player(client_data: Dictionary, spawner_data: PackedByteArray) -> void:
	var player: Node = ClientComponent.instantiate(client_data)
	var save_component: SaveComponent = player.get_node("%SaveComponent")
	var load_error: Error = save_component.load_state()
	
	if load_error == ERR_FILE_NOT_FOUND:
		save_component.deserialize(spawner_data)
	assert(load_error == OK or load_error == ERR_FILE_NOT_FOUND, 
		"Something failed while trying to load player. 
		Error: %s." % error_string(load_error))
	
	var player_data: Dictionary = {
		save=save_component.serialize(),
		client_data=client_data,
	}
	
	spawn(player_data)
