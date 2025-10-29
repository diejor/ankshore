extends Node

@export var port = 21253
@export var ip_address = "vps-1"

var multiplayer_api: MultiplayerAPI = SceneMultiplayer.new()
var multiplayer_peer: MultiplayerPeer = ENetMultiplayerPeer.new()

func _ready():
	if "--no-client" in OS.get_cmdline_args():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	multiplayer_peer.create_client(ip_address, port)
		
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())
	
	var client_msg = "Client (%d)" % multiplayer_peer.get_unique_id()
	print(client_msg + " connecting to ", ip_address, ":", port)

	multiplayer_api.peer_connected.connect(on_peer_connected)

func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, multiplayer_peer.get_unique_id()]
	$TestRPC.rpc_send_message.rpc_id(peer_id, msg)

# We need to manually poll because we are overwriting the MultiplayerAPI.
# Normally, we don't need to do this.
func _process(_delta: float):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
