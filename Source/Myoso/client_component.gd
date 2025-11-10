class_name ClientComponent
extends Node

signal spawn(player_data: Dictionary)

@onready var player: CharacterBody2D = $"../.."

# Functionality needed to allow networking with the server and level.

@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@export var current_scene_uid: int = -1

func _ready() -> void:
	# Debug code, automatically adds a player to the server
	if not GameInstance.is_online():
		if "--local" in OS.get_cmdline_args():
			GameInstance.client.init("localhost", "player")
	
	GameInstance.scene_manager.scene_changed.connect(on_scene_changed)
	GameInstance.client.connected_to_server.connect(on_connected_to_server)
	
	sync.add_visibility_filter(scene_visibility_filter)

func sleep():
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false

func awake():
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.visible = true

func scene_visibility_filter(peer_id: int) -> bool:
	if GameInstance.client.uid == 1 or peer_id == 1:
		return true
		
	# Not sure why we need to set to false the 0 `peer_id`, my guess is that
	# setting it to true would mean that all peer ids are automatically true otherwise
	if peer_id == 0:
		return false
	
	var peer_path = &"Players/%d" % peer_id
	var peer = GameInstance.client.get_node_or_null(peer_path)
	if peer == null:
		#push_warning("Peer is null in GameClient when should not.")
		return false
	
	var peer_client: ClientComponent = peer.get_node_or_null("%ClientComponent")
	assert(peer_client, "For some reason player doesn't have a ClientComponent")
	
	if peer_client.current_scene_uid != current_scene_uid or current_scene_uid == -1:
		peer_client.sleep()
		return false
	else:
		peer_client.awake()
		return true

func on_connected_to_server():
	var player_data = {
		username = GameInstance.client.username,
		peer_id = GameInstance.client.uid,
		position = player.position,
		current_scene_uid = current_scene_uid
	}
	
	GameInstance.client.player_spawner.request_spawn.rpc_id(1, player_data)
	player.queue_free()

func on_scene_changed(current_scene: Node):
	if is_multiplayer_authority():
		current_scene_uid = GameInstance.get_uid_from_path(current_scene.scene_file_path)


func spawn_with_data(player_data: Dictionary):
	# Call deferred so the signal is fired when the player is inside the SceneTree,
	# this is kind of a work around.
	scene_ready.call_deferred(player_data)

func scene_ready(player_data: Dictionary) -> void:
	spawn.emit(player_data)

func _on_spawn(player_data: Dictionary) -> void:
	player.position = player_data.position
	current_scene_uid = player_data.current_scene_uid
