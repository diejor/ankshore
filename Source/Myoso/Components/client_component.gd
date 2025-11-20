class_name ClientComponent
extends Node

## The client component works closely with the client peer instanciated at 
## `GameInstance.client` to make this player controller have a network connection.

signal spawn(player_data: Dictionary)

@onready var player_spawner: PlayerSpawner = owner.get_parent().get_node("%PlayerSpawner")
@onready var owner2d: Node2D = owner
@onready var sync: MultiplayerSynchronizer = %MultiplayerSynchronizer
@export var current_scene_uid: int = -1

func _ready() -> void:
	if not GameInstance.is_online():
		# Debug code, automatically adds a player to the server
		if "--local" in OS.get_cmdline_args():
			# Call deferred because we want to wait for the player to actually be
			# on the scene first. Otherwise `PersistentComponent` might break if this
			# gets called before `PersistentComponent` runs its `_ready`.
			Client.init.call_deferred("localhost", "player")

func sleep() -> void:
	owner.process_mode = Node.PROCESS_MODE_DISABLED
	owner2d.visible = false

func awake() -> void:
	owner.process_mode = Node.PROCESS_MODE_INHERIT
	owner2d.visible = true

## When the client connects, we need to let the server know to spawn us, `PlayerSpawner` 
## will replicate us back.
func on_connected_to_server() -> void:
	var player_data: Dictionary = {
		username = Client.username,
		peer_id = Client.uid,
		position = owner2d.position,
		current_scene_uid = current_scene_uid
	}
	
	player_spawner.request_spawn_player.rpc_id.call_deferred(1, player_data)
	owner.queue_free()
	
func on_peer_disconnected(peer_id: int) -> void:
	if owner.name == str(peer_id):
		owner.queue_free()

func on_scene_changed() -> void:
	if is_multiplayer_authority():
		current_scene_uid = GameInstance.get_uid_from_path(get_tree().current_scene.scene_file_path)

func spawn_with_data(player_data: Dictionary) -> void:
	# Call deferred so the signal is fired when the player is actually inside the SceneTree.
	# This is kind of a work around because it's not clear that `call_deferred` is to wait
	# for the scene to be ready.
	scene_ready.call_deferred(player_data)

func scene_ready(player_data: Dictionary) -> void:
	spawn.emit(player_data)

## Could also be handled directly inside `scene_ready` above.
func _on_spawn(player_data: Dictionary) -> void:
	owner2d.position = player_data.position
	current_scene_uid = player_data.current_scene_uid
