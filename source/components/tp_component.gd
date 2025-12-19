class_name TPComponent
extends Node

signal teleport

var owner2d: Node2D:
	get: return owner as Node2D

@export_file var starting_scene_path: String

@export_group("Replicated")
@export_custom(PROPERTY_HINT_NONE, "replicated") var current_scene: String = "":
	get: return ResourceUID.ensure_path(current_scene)
var current_scene_name: String:
	get: return get_scene_name(current_scene)

func _ready() -> void:
	if current_scene.is_empty():
		current_scene = starting_scene_path
	
	var client: ClientComponent = owner.get_node_or_null("%ClientComponent")
	if client:
		teleport.connect(client._on_teleport)


func begin_teleport(tp_id: String, new_scene: String) -> void:
	var previous_scene_name: String = current_scene_name
	current_scene = new_scene
	var tp_path: String = "%" + tp_id + "/Marker2D"
	
	var save_component: SaveComponent = owner.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.push_to(MultiplayerPeer.TARGET_PEER_SERVER)
	
	Client.scene_manager.teleport.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER,
		owner.name,
		previous_scene_name,
		tp_path
	)

func teleported(scene: Node, _tp_path: String) -> void:
	if scene:
		var tp_node: Marker2D = scene.get_node_or_null(_tp_path)
		if tp_node:
			owner2d.global_position = tp_node.global_position


static func get_scene_name(path_or_uid: String) -> String:
	var path: String = ResourceUID.ensure_path(path_or_uid)
	var scene: PackedScene = load(path)
	var scene_state: SceneState = scene.get_state()
	return scene_state.get_node_name(0)
