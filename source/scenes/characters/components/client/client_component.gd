class_name ClientComponent
extends Node

@export var sync: MultiplayerSynchronizer

func _ready() -> void:
	if "Spawner" in owner.name and not multiplayer.is_server():
		owner.queue_free()
	
	sync.set_visibility_for(MultiplayerPeer.TARGET_PEER_SERVER, true)
	sync.set_visibility_for(get_multiplayer_authority(), true)


func shutdown() -> void:
	sync.set_visibility_for(1, false)


static func instantiate(client_data: Dictionary) -> Node:
	assert(client_data.peer_id)
	assert(client_data.username)
	assert(client_data.scene)
	
	@warning_ignore("unsafe_cast")
	var peer_id: int = client_data.peer_id as int
	@warning_ignore("unsafe_cast")
	var scene_path: String = ResourceUID.ensure_path(client_data.scene as String)
	
	var scene: PackedScene = load(scene_path)
	var player: Node = scene.instantiate()
	player.set_multiplayer_authority(peer_id)
	player.name = str(client_data.username)
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.instantiate()
	
	return player
