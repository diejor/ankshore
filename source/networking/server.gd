# LocalServer.gd (Server side)
extends Node

@export var port = 9000

var smapi := SceneMultiplayer.new()
var enet := ENetMultiplayerPeer.new()

func _ready():
	if not "--server" in OS.get_cmdline_args():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	smapi.root_path = get_path()
	enet.create_server(port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	print("Server ready on ", "*", ":", port)

	smapi.peer_connected.connect(_on_peer_connected)
	
func _on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, enet.get_unique_id()]
	$TestRPC.rpc_id(peer_id, "rpc_send_message", msg)

func _process(_delta: float):
	if smapi.has_multiplayer_peer():
		smapi.poll()
