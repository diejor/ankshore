class_name GameServer
extends Node

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

@export var port := 21253

@onready var lobbies: Node = lobbies_scene.instantiate()

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := WebSocketMultiplayerPeer.new()

const lobbies_scene: PackedScene = preload("res://Source/Networking/Server/Lobbies.tscn")

func _ready() -> void:
	add_child(lobbies)
	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.peer_disconnected.connect(on_peer_disconnected)

func init() -> Error:
	assert(not OS.has_feature("web"),
		"Server.init() cannot run on web builds: %s" % error_string(ERR_UNAVAILABLE))

	var err: Error = multiplayer_peer.create_server(port)
	if err != OK:
		push_warning("create_server failed: %s" % error_string(err))
		return err

	config_api()
	print("Server ready on *:%d" % port)

	return OK

func on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

func config_api() -> void:
	assert(is_instance_valid(lobbies), "Server lobbies node is missing before configuration.")
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = lobbies.get_path()
	get_tree().set_multiplayer(multiplayer_api, lobbies.get_path())

func _process(_dt: float) -> void:
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()

@rpc
func say_hi() -> void:
	print("hi from: ", get_multiplayer_authority())
