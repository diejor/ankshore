class_name ClientComponent
extends Node

## The client component works closely with the client peer instanciated at 
## `GameInstance.client` to make this player controller have a network connection.

signal spawn()

@onready var player_spawner: PlayerSpawner = owner.get_parent().get_node("%PlayerSpawner")

@export var current_scene_uid: int = -1

func _ready() -> void:
	if not GameInstance.is_client():
		push_warning("ClientComponent running without an active client; network features are offline.")

## When the client connects, we need to let the server know to spawn us, `PlayerSpawner` 
## will replicate us back.
func on_connected_to_server() -> void:
	assert(GameInstance.is_client(),
		"`on_connected_to_server` called while the client is offline.")
	var player_data: Dictionary = {
		username = Client.username,
		peer_id = Client.uid
	}
	
	
	player_spawner.request_spawn_player.rpc_id(1, player_data)
	owner.queue_free()
	
func on_peer_disconnected(peer_id: int) -> void:
	if owner.name == str(peer_id):
		owner.queue_free()

func on_scene_changed(current_scene: Node) -> void:
	if is_multiplayer_authority():
		current_scene_uid = GameInstance.get_uid_from_path(current_scene.scene_file_path)

func spawn_client() -> void:
	# Call deferred so the signal is fired when the player is actually inside the SceneTree.
	# This is kind of a work around because it's not clear that `call_deferred` is to wait
	# for the scene to be ready.
	scene_ready.call_deferred()

func scene_ready() -> void:
	spawn.emit()
