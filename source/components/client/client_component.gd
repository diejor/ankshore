class_name ClientComponent
extends Node

@onready var sync: MultiplayerSynchronizer:
	get: return %MultiplayerSynchronizer
@onready var server_visibility: MultiplayerSynchronizer:
	get: return %ServerVisibility


var username_label: RichTextLabel:
	get: return owner.get_node("PlayerHUD/%UsernameLabel")
var username: String:
	get: return username_label.text
	set(user): username_label.text = user

func _enter_tree() -> void:
	server_visibility.set_multiplayer_authority(MultiplayerPeer.TARGET_PEER_SERVER)

func _ready() -> void:
	if "Spawner" in owner.name and not multiplayer.is_server():
		owner.queue_free()
	
	server_visibility.add_visibility_filter(scene_visibility_filter)
	sync.add_visibility_filter(scene_visibility_filter)
	
	username = owner.name
	owner.renamed.connect(func() -> void: username = owner.name)
	
	if owner.has_node("%TPComponent"):
		var tp: TPComponent = owner.get_node("%TPComponent")
		tp.teleport.connect(_on_teleport)


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
	var level_sync: LevelSynchronizer = scene.get_node("%LevelSynchronizer")
	var res: bool = peer_id in level_sync.connected_clients
	return res

static func instantiate(client_data: Dictionary) -> Node:
	assert(client_data.peer_id)
	assert(client_data.username)
	assert(client_data.scene)
	
	var peer_id: int = client_data.peer_id as int
	var scene_path: String = ResourceUID.ensure_path(client_data.scene as String)
	
	var scene: PackedScene = load(scene_path)
	var player: Node = scene.instantiate()
	player.set_multiplayer_authority(peer_id)
	player.name = client_data.username as String
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.instantiate()
	
	var client_component: ClientComponent = player.get_node("%ClientComponent")
	client_component.username = client_data.username as String
	
	return player


### Avoids Synchronizers trying to communicate with the server when the server
### already removed the node.
func _on_teleport() -> void:
	server_visibility.set_visibility_for(0, false)
	sync.set_visibility_for(0, false)
