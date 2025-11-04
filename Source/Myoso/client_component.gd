class_name PlayerClient
extends Node

@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@export var current_scene: int = -1

func _ready() -> void:
	if not GameInstance.is_online():
		if "--local" in OS.get_cmdline_args():
			GameInstance.client.init("localhost", "player")
	
	get_tree().scene_changed.connect(on_scene_changed)
	GameInstance.client.multiplayer_api.connected_to_server.connect(on_connected_to_server)
	
	sync.add_visibility_filter(filter_lobby)

func sleep():
	var p : Node2D = get_parent()
	p.process_mode = Node.PROCESS_MODE_DISABLED
	p.visible = false

func awake():
	var p : Node2D = get_parent()
	p.process_mode = Node.PROCESS_MODE_INHERIT
	p.visible = true

func filter_lobby(peer_id: int) -> bool:
	if GameInstance.client.get_multiplayer_authority() == 1 or peer_id == 1:
		return true
	if peer_id == 0:
		return false
	
	var peer_path = &"Players/%d" % peer_id
	var peer = GameInstance.client.get_node_or_null(peer_path)
	if peer == null:
		push_warning("Peer is null in GameClient when should not.")
		return false
	
	var peer_client: PlayerClient = peer.get_node("%ClientComponent")
	if peer_client.current_scene != current_scene or current_scene == -1:
		peer_client.sleep()
		return false
	else:
		peer_client.awake()
		return true

func on_connected_to_server():
	var uid = GameInstance.client.multiplayer_api.get_unique_id()
	var player_data = {
		username = GameInstance.client.client_username,
		peer_id = uid,
		position = get_parent().position
	}
	
	GameInstance.client.player_spawner.request_spawn.rpc_id(1, player_data)
	get_parent().queue_free()

func on_scene_changed():
	if is_multiplayer_authority():
		current_scene = GameInstance.get_uid_from_path(get_tree().current_scene.scene_file_path)

func on_player_data(player_data: Dictionary):
	get_parent().position = player_data.position
