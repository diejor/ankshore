class_name GameClient
extends Node

signal connected_to_server()
signal peer_connected(peer_id: int)

@export var port := 21253
@export var public_host := "ws.diejor.tech"

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := WebSocketMultiplayerPeer.new()

var username: String
var uid: int:
	get:
		return multiplayer_api.get_unique_id()
	set(value):
		push_warning("Client UID should not be set directly!")

func _ready() -> void:
	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.connected_to_server.connect(on_connected_to_server)

func init(server_address: String, _username: String) -> Error:
	_reset_peer_state()
	var connection_code: Error = create_connection(server_address, _username)
	if connection_code == OK:
		_clear_synchronizers()
		config_api()
		
	return connection_code

func create_connection(server_address: String, _username: String) -> Error:
	username = _username
	var url: String = build_url(server_address)

	var err: Error = multiplayer_peer.create_client(url)
	if err != OK:
		push_warning("Can't create client (%s) to %s" % [error_string(err), url])
		return err
	
	print("Client connecting to ", url)
	
	return OK

func build_url(server_address: String) -> String:
	if server_address.is_empty():
		return "wss://" + public_host

	if server_address == "localhost" or server_address == "127.0.0.1":
		return "ws://localhost:" + str(port)

	return "wss://" + server_address

func on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func on_connected_to_server() -> void:
	print("Client (%d) connected to server." % multiplayer_peer.get_unique_id())
	set_multiplayer_authority(multiplayer_peer.get_unique_id(), false)
	connected_to_server.emit()

func config_api() -> void:
	assert(SceneManager, "SceneManager autoload must exist before configuring the client.")
	var scene_root: NodePath = SceneManager.get_path()
	assert(scene_root != NodePath(""), "SceneManager path must be valid before client configuration.")

	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = scene_root
	get_tree().set_multiplayer(multiplayer_api, scene_root)

func _process(_dt: float) -> void:
	if multiplayer_api.has_multiplayer_peer() and multiplayer_api.multiplayer_peer is not OfflineMultiplayerPeer:
		multiplayer_api.poll()

func _reset_peer_state() -> void:
	if multiplayer_api.has_multiplayer_peer() and multiplayer_api.multiplayer_peer is WebSocketMultiplayerPeer:
		var previous_peer: WebSocketMultiplayerPeer = multiplayer_api.multiplayer_peer
		if previous_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
			previous_peer.close()

	multiplayer_api.multiplayer_peer = OfflineMultiplayerPeer.new()
	multiplayer_peer = WebSocketMultiplayerPeer.new()

func _clear_synchronizers() -> void:
	# Fixes a weird bug where `MultiplayerSynchronizers` think they are connected
	# to the server when they are offline.
	for synchronizer in get_tree().get_nodes_in_group("synchronizers"):
			synchronizer.queue_free()
	while not get_tree().get_nodes_in_group("synchronizers").is_empty():
		await get_tree().create_timer(0.01).timeout
