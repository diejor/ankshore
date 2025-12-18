class_name SceneManager
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
	
	var player: Node2D = scene.get_node(username)

	player.queue_free()
	
	return player


@rpc("any_peer", "call_remote", "reliable")
func teleport(
	username: String, 
	from_scene_name: String, 
	tp_path: String) -> void:
	var from_scene: Node = get_node(from_scene_name)
	var from_scene_sync: SceneSynchronizer = from_scene.get_node("%SceneSynchronizer")
	
	var player: Node2D = from_scene.get_node(username)
	var client: ClientComponent = player.get_node("%ClientComponent")
	var tp_component: TPComponent = player.get_node("%TPComponent")
	
	await client.state_sync.delta_synchronized # Make sure the player has been updated
	tp_component.emit_teleport.rpc_id(player.get_multiplayer_authority())
	await client.shutdown
	
	
	var to_scene: Node = get_node(tp_component.current_scene_name)
	var to_scene_sync: SceneSynchronizer = to_scene.get_node("%SceneSynchronizer")
	
	
	var flip := func(event: Signal, from: Callable, to: Callable) -> void:
		event.disconnect(from)
		event.connect(to.bind(player))
		if event == player.tree_exiting:
			tp_component.teleported(to_scene, tp_path)
			player.request_ready()
	
	var from_spawn := from_scene_sync._on_spawned
	var to_spawn := to_scene_sync._on_spawned
	var from_despawn := from_scene_sync._on_despawned
	var to_despawn := to_scene_sync._on_despawned
	
	flip.call(player.tree_entered, from_spawn, to_spawn)
	
	player.tree_entered.connect(flip.bind(player.tree_exiting, from_despawn, to_despawn))
	player.reparent(to_scene)
	player.tree_entered.disconnect(flip)


@rpc("any_peer", "call_remote", "reliable")
func connect_player(
	client_data: Dictionary, 
	destination_scene_name: String = "", 
	tp_path: String = "") -> void:
	var player: Node2D = ClientComponent.instantiate(client_data)
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	var load_err: Error
	if save_component:
		load_err = save_component.load_state()
		assert(load_err == OK or load_err == ERR_FILE_NOT_FOUND, 
			"Something failed while trying to load player. 
			Error: %s." % error_string(load_err))
	
	var tp_component: TPComponent = player.get_node_or_null("%TPComponent")
	if tp_component and destination_scene_name.is_empty() and not tp_component.current_scene.is_empty():
		destination_scene_name = tp_component.current_scene_name
	elif destination_scene_name.is_empty():
		destination_scene_name = TPComponent.get_scene_name(tp_component.starting_scene_path)
	
	
	var destination_scene: Node = get_node_or_null(destination_scene_name)
	
	if tp_component:
		if tp_component.current_scene.is_empty():
			tp_component.current_scene = destination_scene.scene_file_path
		tp_component.teleported(destination_scene, tp_path)
		
	if save_component and load_err == ERR_FILE_NOT_FOUND:
		# No player save found, create from spawner.
		var spawner_name := save_component.spawner_name()
		var spawner := destination_scene.get_node("%" + spawner_name)
		var spawner_save := spawner.get_node_or_null("%SaveComponent")
		if spawner_save:
			save_component = spawner_save
	
	var scene_sync: SceneSynchronizer = destination_scene.get_node("%SceneSynchronizer")
	if multiplayer.is_server():
		scene_sync.track_player(player)
	
	destination_scene.add_child(player)
