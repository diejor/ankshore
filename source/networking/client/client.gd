class_name GameClient
extends Node


signal connected_to_server()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)


const SCENE_MANAGER: PackedScene = preload("uid://d3ag2052swfwd")
@onready var scene_manager: SceneManager = SCENE_MANAGER.instantiate()


var multiplayer_api: SceneMultiplayer:
	get: return backend.multiplayer_api
var multiplayer_peer: MultiplayerPeer:
	get: return backend.multiplayer_peer
var uid: int:
	get: return multiplayer_api.get_unique_id()
	set(value): push_warning("Client UID should not be set directly.")

var backend: MultiplayerClientBackend

var username: String = "":
	get:
		if username.is_empty():
			var candidate := OS.get_environment("USERNAME")
			if candidate.is_empty():
				return "player"
			return candidate
		else:
			return username


func _ready() -> void:
	add_child(scene_manager)

	# Connect multiplayer signals.
	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.peer_disconnected.connect(on_peer_disconnected)
	multiplayer_api.connected_to_server.connect(on_connected_to_server)

	# Boot local client
	var client_err: Error = connect_client("localhost", username)
	if client_err != OK:
		push_warning(
			"Local client bootstrap failed: %s" % error_string(client_err))


func connect_client(server_address: String, _username: String) -> Error:
	return init(server_address, _username)


func init(server_address: String, _username: String) -> Error:
	username = _username
	backend.peer_reset_state()

	var connection_code: Error = backend.create_connection(
		server_address, _username)
	if connection_code == OK:
		config_api()

	return connection_code


func config_api() -> void:
	assert(scene_manager, 
		"SceneManager autoload must exist before configuring the client.")
	var scene_root: NodePath = scene_manager.get_path()
	assert(scene_root != NodePath(""), 
		"SceneManager path must be valid before client configuration.")

	backend.configure_tree(get_tree(), scene_root)


func on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)


func on_connected_to_server() -> void:
	print("Client (%d) connected to server." % multiplayer_api.get_unique_id())
	set_multiplayer_authority(multiplayer_api.get_unique_id(), false)
	connected_to_server.emit()


func _process(dt: float) -> void:
	if backend:
		backend.poll(dt)
