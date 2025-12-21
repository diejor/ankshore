class_name ClientComponent
extends Node

@export var state_sync: StateSynchronizer

@export_group("Replicated")
var username_label: RichTextLabel:
	get: return %ClientHUD/%UsernameLabel
@export var username: String = "":
	set(user):
		username = user
		username_label.text = user


func _ready() -> void:
	if "Spawner" in owner.name and not multiplayer.is_server():
		owner.queue_free()

static func instantiate(client_data: Dictionary) -> Node:
	assert(client_data.peer_id)
	
	assert(client_data.scene)
	
	var peer_id: int = client_data.peer_id
	var scene_path: String = ResourceUID.ensure_path(client_data.scene as String)
	
	var scene: PackedScene = load(scene_path)
	var player: Node = scene.instantiate()
	player.set_multiplayer_authority(peer_id)
	player.name = str(client_data.peer_id)
	
	var client: ClientComponent = player.get_node_or_null("%ClientComponent")
	if client:
		assert(client_data.username)
		client.username = client_data.username
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.instantiate()
	
	return player

func _on_teleport() -> void:
	state_sync.only_server()
