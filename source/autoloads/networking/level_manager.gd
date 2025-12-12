class_name LevelManager
extends MultiplayerSpawner

@export_file var areas_path: Array[String]

func _ready() -> void:
	spawn_function = spawn_lobby
	
	spawn_lobbies.call_deferred()


func spawn_lobbies() -> void:
	if multiplayer.is_server():
		for path in areas_path:
			spawn(path)


func spawn_lobby(lobby_file_path: String) -> Node:
	var lobby_scene: PackedScene = load(lobby_file_path)
	var lobby: Node2D = lobby_scene.instantiate()
	
	if multiplayer.is_server():
		lobby.visible = false
		lobby.process_mode = Node.PROCESS_MODE_DISABLED 
	return lobby


func remove_peer(username: String, scene_name: String) -> Node2D:
	var scene: Node = get_node(scene_name)
	var level_synchronizer: MultiplayerSynchronizer = scene.get_node("%LevelSynchronizer")
	var player: Node2D = scene.get_node(username)

	player.queue_free()
	await player.tree_exited
	level_synchronizer.set_visibility_for(player.get_multiplayer_authority(), false)
	
	return player


@rpc("any_peer", "call_remote", "reliable")
func teleport(
	username: String, 
	from_scene_name: String, 
	destination_scene_name: String, 
	tp_path: String) -> void:
	var removed_player: Node2D = await remove_peer(username, from_scene_name)
	
	var client_data: Dictionary = {
		peer_id = removed_player.get_multiplayer_authority(),
		username = removed_player.name,
		scene = removed_player.scene_file_path
	}
	
	connect_player(client_data, destination_scene_name, tp_path)


@rpc("any_peer", "call_remote", "reliable")
func connect_player(
	client_data: Dictionary, 
	destination_scene_name: String = "", 
	tp_path: String = "") -> void:
	var player: Node2D = ClientComponent.instantiate(client_data)
	var save_component: SaveComponent = player.get_node("%SaveComponent")
	var tp_component: TPComponent = player.get_node("%TPComponent")
	
	var load_error: Error = save_component.load_state()
	assert(load_error == OK or load_error == ERR_FILE_NOT_FOUND, 
		"Something failed while trying to load player. 
		Error: %s." % error_string(load_error))
	
	var destination_scene: Node = get_node_or_null(destination_scene_name)
	tp_component.teleported(destination_scene, tp_path)
	
	
	var player_data: Dictionary = {
		save=save_component.serialize_scene(),
		client_data=client_data,
	}
	
	var current_scene: Node = get_node(tp_component.current_scene_name)
	var player_spawner: PlayerSpawner = current_scene.get_node("PlayerSpawner")
	var level_sync: MultiplayerSynchronizer = current_scene.get_node("LevelSynchronizer")
	level_sync.set_visibility_for(client_data.peer_id as int, true)
	player_spawner.spawn(player_data)
