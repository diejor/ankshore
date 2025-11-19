class_name ClientComponent
extends Node

## The client component works closely with the client peer instanciated at 
## `GameInstance.client` to make this player controller have a network connection.

signal spawn(player_data: Dictionary)

@onready var owner2d: Node2D = owner
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@export var current_scene_uid: int = -1

func _ready() -> void:
	# Debug code, automatically adds a player to the server
	if not GameInstance.is_online():
		if "--local" in OS.get_cmdline_args():
			# Call deferred because we want to wait for the player to actually be
			# on the scene first. Otherwise `PersistentComponent` might break if this
			# gets called before `PersistentComponent` runs its `_ready`.
			GameInstance.client.init.call_deferred("localhost", "player")
	
	sync.add_visibility_filter(scene_visibility_filter)

## This filter allows us to hide and not process players that are on different scenes.
## As a bonus we save some bandwidth since the `MultiplayerSynchronizer` will not
## replicate players that are not visible to each other.
func scene_visibility_filter(peer_id: int) -> bool:
	if GameInstance.client.uid == 1 or peer_id == 1:
		return true
		
	# Not sure why we need to set to false when `peer_id` equals `0`, my guess is that
	# setting it to true would mean that all peer ids have `true` visibility,
	# therefore, the filter would not be called for specific peer ids.
	if peer_id == 0:
		return false
	
	var peer_path: NodePath = &"Players/%d" % peer_id
	var peer: Node = GameInstance.client.get_node_or_null(peer_path)
	if peer == null:
		#push_warning("Peer is null in GameClient when should not.")
		return false
	
	var peer_client: ClientComponent = peer.get_node_or_null("%ClientComponent")
	assert(peer_client, "For some reason peer doesn't have a ClientComponent")
	
	if peer_client.current_scene_uid != current_scene_uid or current_scene_uid == -1:
		peer_client.sleep()
		return false
	else:
		peer_client.awake()
		return true

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
		username = GameInstance.client.username,
		peer_id = GameInstance.client.uid,
		position = owner2d.position,
		current_scene_uid = current_scene_uid
	}
	
	GameInstance.client.player_spawner.request_spawn.rpc_id(1, player_data)
	owner.queue_free()

func on_scene_changed(current_scene: Node) -> void:
	if is_multiplayer_authority():
		current_scene_uid = GameInstance.get_uid_from_path(current_scene.scene_file_path)

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
