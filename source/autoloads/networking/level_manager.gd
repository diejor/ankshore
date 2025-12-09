class_name LevelManager
extends MultiplayerSpawner

@export_file var starting_scene_path: String

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


@rpc("any_peer", "call_remote")
func remove_peer(peer_id: int, scene_name: String) -> void:
	var scene: Node = get_node(scene_name)
	var level_synchronizer: MultiplayerSynchronizer = scene.get_node("%LevelSynchronizer")

	var player: Node = scene.get_node(str(peer_id))
	player.queue_free()
	await player.tree_exited
	level_synchronizer.set_visibility_for(peer_id, false)

@rpc("any_peer", "call_remote", "reliable")
func teleport(peer_id: int, username: String, from_scene_name: String, destination_scene_name: String) -> void:
	var from_scene: Node = get_node(from_scene_name)
	var destination_scene: Node = get_node(destination_scene_name)
	
	var player: Node = from_scene.get_node(username)
	var tp_component: TPComponent = player.get_node("%TPComponent")
	var save_component: SaveComponent = player.get_node("%SaveComponent")
	
	var level_synchronizer: MultiplayerSynchronizer = from_scene.get_node("%LevelSynchronizer")
	
	tp_component.current_scene = destination_scene.scene_file_path
	save_component.pull_from_scene()
	save_component.save_state()
	player.queue_free()
	await player.tree_exited
	level_synchronizer.set_visibility_for(peer_id, false)
	
	level_synchronizer = destination_scene.get_node("%LevelSynchronizer")
	
	var client_data: Dictionary = {
		username = username,
		peer_id = peer_id,
		scene=player.scene_file_path
	}
	
	player = ClientComponent.instantiate(client_data)
	save_component = player.get_node("%SaveComponent")
	tp_component = player.get_node("%TPComponent")
	
	var load_error: Error = save_component.load_state()
	assert(load_error == OK or load_error == ERR_FILE_NOT_FOUND, 
		"Something failed while trying to load player. 
		Error: %s." % error_string(load_error))
	
	var player_data: Dictionary = {
		save=save_component.serialize_scene(),
		client_data=client_data,
	}
	
	var current_scene: Node = get_node(tp_component.current_scene_name)
	var player_spawner: PlayerSpawner = current_scene.get_node("PlayerSpawner")
	var level_sync: MultiplayerSynchronizer = current_scene.get_node("LevelSynchronizer")
	level_sync.set_visibility_for(client_data.peer_id as int, true)
	player_spawner.spawn(player_data)
	

@rpc("any_peer", "call_remote", "reliable")
func connect_player(client_data: Dictionary) -> void:
	var player: Node = ClientComponent.instantiate(client_data)
	var save_component: SaveComponent = player.get_node("%SaveComponent")
	var tp_component: TPComponent = player.get_node("%TPComponent")
	
	var load_error: Error = save_component.load_state()
	assert(load_error == OK or load_error == ERR_FILE_NOT_FOUND, 
		"Something failed while trying to load player. 
		Error: %s." % error_string(load_error))
	
	if tp_component.current_scene.is_empty():
		tp_component.current_scene = starting_scene_path
	
	var player_data: Dictionary = {
		save=save_component.serialize_scene(),
		client_data=client_data,
	}
	
	var current_scene: Node = get_node(tp_component.current_scene_name)
	var player_spawner: PlayerSpawner = current_scene.get_node("PlayerSpawner")
	var level_sync: MultiplayerSynchronizer = current_scene.get_node("LevelSynchronizer")
	level_sync.set_visibility_for(client_data.peer_id as int, true)
	player_spawner.spawn(player_data)
