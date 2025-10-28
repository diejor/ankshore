extends Node

@export var port = 9000
@export var ip_address = "127.0.0.1"

var smapi := SceneMultiplayer.new()
var enet := ENetMultiplayerPeer.new()

func _ready():
	smapi.root_path = get_path()
	enet.create_client(ip_address, port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	print("Client connecting to ", ip_address, ":", port)

	smapi.peer_connected.connect(on_peer_connected)

func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, enet.get_unique_id()]
	$TestRPC.rpc_id(peer_id, "rpc_send_message", msg)

func _process(_dt):
	if smapi.has_multiplayer_peer():
		smapi.poll()
