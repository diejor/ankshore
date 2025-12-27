class_name SceneSpawner
extends MultiplayerSpawner

@onready var scene_sync: SceneSynchronizer = %SceneSynchronizer
@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player


func spawn_player(client_data: Dictionary) -> Node:
	var player: Node2D = ClientComponent.instantiate(client_data)
	if not multiplayer.is_server():
		return player
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	
	var load_err: Error
	if save_component:
		load_err = save_component.load_state()
		assert(load_err == OK or load_err == ERR_FILE_NOT_FOUND, 
			"Something failed while trying to load player. 
			Error: %s." % error_string(load_err))
	
	var tp_component: TPComponent = player.get_node("%TPComponent")
	var world: SubViewport = get_parent()
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
	
	scene_sync.track_player(player)
	
	return player
