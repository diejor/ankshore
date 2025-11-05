class_name GameClient
extends Node2D

signal connected_to_server()
signal peer_connected(peer_id: int)

@onready var player_spawner: MultiplayerSpawner = $Players/PlayerSpawner

@export var port := 21253
@export var public_host := "ws.diejor.tech"

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := WebSocketMultiplayerPeer.new()

var username
var uid: int:
	get:
		return multiplayer_api.get_unique_id()
	set(value):
		push_warning("Client UID should not be set directly!")

func _ready():
	if "--server" in OS.get_cmdline_args():
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.connected_to_server.connect(on_connected_to_server)

func init(server_address: String, _username: String):
	username = _username
	var url := build_url(server_address)

	var err := multiplayer_peer.create_client(url)
	if err != OK:
		push_warning("Can't create client (%s) to %s" % [err, url])
		return err

	config_api()
	print("Client connecting to ", url)
	return OK

func build_url(server_address: String) -> String:
	if server_address == "localhost" or server_address == "127.0.0.1":
		return "ws://localhost:" + str(port)

	return "wss://" + public_host

func on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func on_connected_to_server() -> void:
	connected_to_server.emit()
	print("Client (%d) connected to server." % multiplayer_peer.get_unique_id())
	set_multiplayer_authority(multiplayer_peer.get_unique_id(), false)

func config_api():
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())

func _process(_dt):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
