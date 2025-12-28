class_name LobbyManager
extends MultiplayerSpawner

@export_file("*.tscn") var lobbies: Array[String]
@export_file("*.tscn") var world_server_path: String
@export_file("*.tscn") var world_client_path: String

func _ready() -> void:
	spawn_function = spawn_lobby
	spawn_lobbies.call_deferred()


func spawn_lobbies() -> void:
	if multiplayer.is_server():
		for lobby_path: String in lobbies:
			spawn(lobby_path)


func spawn_lobby(lobby_file_path: String) -> Node:
	var lobby_scene: PackedScene = load(lobby_file_path)
	var lobby: Node = lobby_scene.instantiate()
	
	var world_path: String
	if multiplayer.is_server():
		world_path = world_server_path
	else:
		world_path = world_client_path
	var world_scene: PackedScene = load(world_path)
	var world: Node = world_scene.instantiate()
	
	var scene_spawner: MultiplayerSpawner = world.get_node("%SceneSpawner")
	scene_spawner.spawn_path = "../" + lobby.name
	
	world.name = lobby.name + world.name
	world.add_child(lobby)
	
	return world


@rpc("any_peer", "call_remote", "reliable")
func request_teleport(
	username: String, 
	from_scene_name: String, 
	tp_path: String) -> void:
	var from_world: Node = get_node(from_scene_name + "World")
	var from_scene: Node = from_world.get_node(from_scene_name)
	var from_scene_sync: SceneSynchronizer = from_world.get_node("%SceneSynchronizer")
	
	var player: Node2D = from_scene.get_node(username)
	var tp_component: TPComponent = player.get_node("%TPComponent")
	
	var state: StateSynchronizer = player.get_node_or_null("%StateSynchronizer")
	if state: # TODO: add a timeout for the case the client never synchronizes
		await state.delta_synchronized # Make sure the player has been updated
	
	var to_world: Node = get_node(tp_component.current_scene_name + "World")
	var to_scene: Node = to_world.get_node(tp_component.current_scene_name)
	var to_scene_sync: SceneSynchronizer = to_world.get_node("%SceneSynchronizer")
	
	var flip := func(event: Signal, from: Callable, to: Callable) -> void:
		event.disconnect(from)
		event.connect(to.bind(player))
		if event == player.tree_exiting:
			player.request_ready()
			tp_component.teleported(to_scene, tp_path)
	
	var from_spawn := from_scene_sync._on_spawned
	var to_spawn := to_scene_sync._on_spawned
	var from_despawn := from_scene_sync._on_despawned
	var to_despawn := to_scene_sync._on_despawned
	
	flip.call(player.tree_entered, from_spawn, to_spawn)
	
	player.tree_entered.connect(flip.bind(player.tree_exiting, from_despawn, to_despawn))
	player.reparent(to_scene)
	player.tree_entered.disconnect(flip)


@rpc("any_peer", "call_remote", "reliable")
func request_connect_player(
	client_data: Dictionary) -> void:
	var player: Node2D = ClientComponent.instantiate(client_data)
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	
	var load_err: Error
	if save_component:
		load_err = save_component.load_state()
		assert(load_err == OK or load_err == ERR_FILE_NOT_FOUND, 
			"Something failed while trying to load player. 
			Error: %s." % error_string(load_err))
	
	var tp_component: TPComponent = player.get_node("%TPComponent")
	var world: SubViewport = get_node(tp_component.current_scene_name + "World")
	var destination_scene: Node = world.get_node(tp_component.current_scene_name)
	
	var client: ClientComponent = player.get_node("%ClientComponent")
	if client and load_err == ERR_FILE_NOT_FOUND:
		# No player save found, create from spawner.
		var spawner_name := client.spawner_name()
		var spawner := destination_scene.get_node("%" + spawner_name)
		var spawner_save: SaveComponent = spawner.get_node_or_null("%SaveComponent")
		if spawner_save:
			save_component.deserialize_scene(spawner_save.serialize_scene())
		client.username = client_data.username
	
	var scene_sync: SceneSynchronizer = world.get_node("%SceneSynchronizer")
	scene_sync.track_player(player)
	
	destination_scene.add_child(player)
