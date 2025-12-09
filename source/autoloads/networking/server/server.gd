class_name GameServer
extends Node

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var backend: MultiplayerServerBackend

const LEVEL_MANAGER: PackedScene = preload("uid://d3ag2052swfwd")
@onready var level_manager: LevelManager = LEVEL_MANAGER.instantiate()


var multiplayer_api: SceneMultiplayer:
	get: return backend.multiplayer_api
var multiplayer_peer: MultiplayerPeer:
	get: return backend.multiplayer_peer
var root: String: 
	get: return multiplayer_api.root_path

func _ready() -> void:
	add_child(level_manager)

	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.peer_disconnected.connect(on_peer_disconnected)

	var server_err := init()
	assert(server_err == OK,
		"Dedicated server failed to start: %s" % error_string(server_err))

func init() -> Error:
	backend.peer_reset_state()
	var err: Error = backend.create_server()
	if err != OK:
		return err

	config_api()
	return OK

func config_api() -> void:
	assert(is_instance_valid(level_manager), 
		"Server lobbies node is missing before configuration.")
	backend.configure_tree(get_tree(), level_manager.get_path())

func on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

func _process(dt: float) -> void:
	if backend:
		backend.poll(dt)
