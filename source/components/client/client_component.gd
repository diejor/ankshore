class_name ClientComponent
extends Node

@export var replicated_properties: MultiplayerSynchronizer
var server_visibility: MultiplayerSynchronizer:
	get: return $ServerVisibility
var root_path: NodePath:
	get: return server_visibility.get_path_to(owner)

@export_group("Replicated")
var username_label: RichTextLabel:
	get: return %ClientHUD/%UsernameLabel
@export var username: String = "":
	get: return username_label.text
	set(user): username_label.text = user

func _enter_tree() -> void:
	server_visibility.root_path = root_path
	server_visibility.set_multiplayer_authority(MultiplayerPeer.TARGET_PEER_SERVER)

func _ready() -> void:
	assert(server_visibility.public_visibility == true)
	if "Spawner" in owner.name and not multiplayer.is_server():
		owner.queue_free()
	
	server_visibility.add_visibility_filter(scene_visibility_filter)
	replicated_properties.add_visibility_filter(scene_visibility_filter)
	
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
	var scene_sync: SceneSynchronizer = scene.get_node("%SceneSynchronizer")
	var res: bool = peer_id in scene_sync.connected_clients
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


### Effectively disables Synchronizers trying to communicate with the server 
### when the server already removed the node.
func _on_teleport() -> void:
	server_visibility.set_visibility_for(0, false)
	replicated_properties.set_visibility_for(0, false)
