class_name PlayerClient
extends Node

@onready var game_client: GameClient = $"/root/GameInstance/%Network/%GameClient"
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var current_scene: int

func _ready() -> void:
	
	if not GameInstance.is_online():
		if "--local" in OS.get_cmdline_args():
			game_client.init("localhost", "player")
	
	get_tree().scene_changed.connect(on_scene_changed)
	
	if game_client:
		game_client.multiplayer_api.connected_to_server.connect(on_connected_to_server)
	
	sync.add_visibility_filter(filter_lobby)

func filter_lobby(peer_id: int) -> bool:
	
	if game_client.get_multiplayer_authority() == 1 or peer_id == 1:
		return true
	if peer_id == 0:
		return false
	
	var peer_path = &"Players/%d" % peer_id
	if game_client.has_node(peer_path):
		var peer = game_client.get_node(peer_path)
		var peer_client: PlayerClient = peer.get_node("%ClientComponent")
		if peer_client.current_scene != current_scene:
			peer.process_mode = Node.PROCESS_MODE_DISABLED
			peer.visible = false
			return false
		else:
			peer.process_mode = Node.PROCESS_MODE_INHERIT
			peer.visible = true
			return true
		
	return true

func on_connected_to_server():
	var uid = game_client.multiplayer_api.get_unique_id()
	var player_data = {
		current_scene = current_scene,
		username = game_client.client_username,
		peer_id = uid,
		position = get_parent().position
	}
	
	game_client.player_spawner.request_spawn.rpc_id(1, player_data)
	get_parent().queue_free()

func on_scene_changed():
	if is_multiplayer_authority():
		current_scene = GameInstance.get_uid_from_path(get_tree().current_scene.scene_file_path)

func on_player_data(player_data: Dictionary):
	get_parent().position = player_data.position
	current_scene = player_data.current_scene
