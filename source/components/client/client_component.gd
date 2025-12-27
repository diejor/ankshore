class_name ClientComponent
extends NodeComponent


@export_group("Replicated")
@export_custom(PROPERTY_HINT_NONE, "replicated") 
var username: String = "":
	set(user):
		username = user
		username_label.text = user

var username_label: RichTextLabel:
	get: return %ClientHUD/%UsernameLabel

func _ready() -> void:
	super._ready()
	if "Spawner" in owner.name and not multiplayer.is_server():
		owner.queue_free()
	
	assert(owner.tree_entered.is_connected(_on_owner_tree_entered),
		"Signal `tree_entered` of `%s` must be connected to `%s`, otherwise, \
the authority will not be set correctly." % [owner.name, _on_owner_tree_entered])

static func instantiate(client_data: Dictionary) -> Node:
	assert(client_data.peer_id)
	assert(client_data.scene)
	assert(client_data.username)
	
	var peer_id: int = client_data.peer_id
	var scene_path: String = ResourceUID.ensure_path(client_data.scene as String)
	
	var scene: PackedScene = load(scene_path)
	var player: Node = scene.instantiate()
	
	var client: ClientComponent = player.get_node("%ClientComponent")
	client.username = client_data.username
	player.name = client.username + "|" + str(peer_id)
		
	
	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.instantiate()
	
	return player


func spawner_name() -> String:
	return TPComponent.get_scene_name(owner.scene_file_path)


func _on_owner_tree_entered() -> void:
	assert(owner.name != "|")
	var name_authority: PackedStringArray = owner.name.split("|")
	if name_authority.size() == 2:
		var authority: int = name_authority[1].to_int()
		assert(authority != 0)
		owner.set_multiplayer_authority(authority)
