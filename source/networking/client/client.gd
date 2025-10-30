class_name GameClient
extends Node

@export var port = 21253

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := ENetMultiplayerPeer.new()


func _ready():
	if "--server" in OS.get_cmdline_args():
		process_mode = Node.PROCESS_MODE_DISABLED
		return


func create_client(server_address: String):
	multiplayer_peer.create_client(server_address, port)
		
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())
	
	set_multiplayer_authority(multiplayer_peer.get_unique_id())
	$Players/PlayerSpawner.set_multiplayer_authority(1)
	var client_msg = "Client (%d)" % get_multiplayer_authority()
	print(client_msg + " connecting to ", server_address, ":", port)

	multiplayer_api.peer_connected.connect(on_peer_connected)


func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, get_multiplayer_authority()]
	$TestRPC.rpc_send_message.rpc_id(peer_id, msg)


# We need to manually poll because we are overwriting the MultiplayerAPI of the root.
func _process(_delta: float):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
