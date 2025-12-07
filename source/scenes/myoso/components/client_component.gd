class_name ClientComponent
extends Node

@export var is_active: IsActive

@onready var autoload_signals: AutoloadSignals = %AutoloadSignals
@onready var player_spawner: PlayerSpawner = owner.get_parent().get_node("%PlayerSpawner")


func _ready() -> void:
	if not GameInstance.is_client():
		push_warning("Running without an active client")

	# Remove spawners.
	assert(not is_active.resource_local_to_scene,
		"In order to detect active players, `%s` resource must not be local
		to scene." % is_active)
	var spawner_node: Node = owner.get_node_or_null("%" + owner.name)

	if is_active.active and spawner_node != null:
		spawner_node.queue_free()


func _on_scene_changed(_current_scene: Node, _old_scene: Node) -> void:
	assert(GameInstance.is_client())
	if is_active.active:
		return
	is_active.active = true
	var client_data: Dictionary = {
		username = Client.username,
		peer_id = Client.uid,
		scene=owner.scene_file_path
	}

	var save_component: SaveComponent = owner.get_node("%SaveComponent")
	save_component.pull_from_scene()
	player_spawner.request_spawn_player.rpc_id(
		1, 
		client_data, 
		save_component.serialize())
	
	owner.queue_free()


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
	
	var save_component: SaveComponent = player.get_node("%SaveComponent")
	save_component.instantiate.emit()
	
	return player
