class_name TPComponent
extends Node

@onready var owner2d: Node2D = owner as Node2D
@onready var save_component: SaveComponent = %SaveComponent

var tp_destination: String

@export var current_scene_name: String = ""
@export var name_to_scene: Dictionary[StringName, String]

func _ready() -> void:
	if current_scene_name.is_empty():
		current_scene_name = SceneManager.current_scene.name

func begin_teleport(_tp_destination: String) -> void:
	assert(not _tp_destination.is_empty(), "Teleporting to an unnamed `TPArea` is not valid.")

	tp_destination = _tp_destination
	
	# Move the player far from tp area before the scene changes,
	# fixes the bug of phantom `body_entered` signals after player 
	# already teleported.
	owner2d.global_position.y += 999999999

## If `on_scene_changed` was called it probably means the player is trying to 
## teleport. A player will actually teleport to a `TPArea` if they called 
## `begin_teleport` before switching the scene.
func on_scene_changed(current_scene: Node, _old_scene: Node) -> void:
	current_scene_name = current_scene.name
	
	if not tp_destination.is_empty():
		var tp_path: String = "%" + tp_destination + "/Marker2D"
		var tp_node: Marker2D = current_scene.get_node_or_null(tp_path)
		owner2d.global_position = tp_node.global_position
		var camera: Camera2D = owner.get_node("Camera2D")
		camera.reset_smoothing()
	
	if is_multiplayer_authority():
		SceneManager.teleport(owner)
		save_component.force_state_sync()
		var player_data: Dictionary = {
			username = Client.username,
			peer_id = Client.uid,
		}
		request_teleport.rpc_id(1, player_data)

@rpc("any_peer", "call_remote")
func request_teleport(player_data: Dictionary) -> void:
	var lobby_path: NodePath = NodePath(
		str(Server.multiplayer_api.root_path) + "/%" + current_scene_name)
	var lobby: Node = get_node_or_null(lobby_path)
	var lobby_spawner: PlayerSpawner = lobby.get_node("%PlayerSpawner")
	
	owner.queue_free()
	@warning_ignore("unsafe_cast")
	lobby_spawner.request_spawn_player(player_data)


func on_spawn() -> void:
	var camera: Camera2D = owner.get_node("%Camera2D")
	camera.reset_smoothing()
	var is_incorrect_scene_name: bool = current_scene_name != SceneManager.current_scene.name
	if not current_scene_name.is_empty() and is_incorrect_scene_name and is_multiplayer_authority():
		get_tree().change_scene_to_file(name_to_scene[current_scene_name])
