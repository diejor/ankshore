class_name ClientComponent
extends Node

@export var state_sync: StateSynchronizer
@export var spawn_sync: SpawnSynchronizer

func _ready() -> void:
	assert(spawn_sync.public_visibility == true)
	if "Spawner" in owner.name and not multiplayer.is_server():
		owner.queue_free()
	
	spawn_sync.add_visibility_filter(scene_visibility_filter)
	state_sync.add_visibility_filter(scene_visibility_filter)
	

func scene_visibility_filter(peer_id: int) -> bool:
	if "Spawner" in owner.name:
		return false
	if peer_id == MultiplayerPeer.TARGET_PEER_SERVER:
		return true
		
	# Not sure why we need to set to false when `peer_id` equals `0`, my guess is that
	# setting it to true would mean that all peer ids have `true` visibility,
	# therefore, the filter would not be called for specific peer ids.
	if peer_id == 0:
		return false
	
	var scene: Node = owner.get_parent()
	var scene_sync: SceneSynchronizer = scene.get_node("%SceneSynchronizer")
	var res: bool = peer_id in scene_sync.connected_clients
	return res

static func instantiate(client_data: Dictionary) -> Node:
	assert(client_data.peer_id)
	assert(client_data.username)
	assert(client_data.scene)
	
	var peer_id: int = client_data.peer_id
	var scene_path: String = ResourceUID.ensure_path(client_data.scene as String)
	
	var scene: PackedScene = load(scene_path)
	var player: Node = scene.instantiate()
	player.set_multiplayer_authority(peer_id)
	player.name = str(client_data.peer_id)
	
	var _state_sync: StateSynchronizer = player.get_node("%StateSynchronizer")
	_state_sync.username = client_data.username
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.instantiate()
	
	return player


func _on_teleport() -> void:
	#state_sync.set_visibility_for(0, false)
	spawn_sync.set_visibility_for(0, false)
