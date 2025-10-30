class_name GameServer
extends Node

@export var port = 21253

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := ENetMultiplayerPeer.new()

func _ready():
	if "--server" in OS.get_cmdline_args():
		create_server()

func create_server() -> Error:
	var creation_result: Error = multiplayer_peer.create_server(port)
	
	# Early exit if peer can't create server, most likely because port is not available
	if creation_result == ERR_CANT_CREATE:
		return creation_result
	
	multiplayer_api.root_path = get_path()
	multiplayer_api.multiplayer_peer = multiplayer_peer
	
	get_tree().set_multiplayer(multiplayer_api, get_path())
	
	print("Server ready on ", "*", ":", port)

	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.peer_disconnected.connect(on_peer_disconnected)
	
	return creation_result


func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, multiplayer_peer.get_unique_id()]
	$TestRPC.rpc_send_message.rpc_id(peer_id,  msg)
	
	$Players/PlayerSpawner.spawn(peer_id)

func on_peer_disconnected(peer_id: int) -> void:
	for child in $Players.get_children():
		if int(child.name) == peer_id:
			child.queue_free()


# We need to manually poll because we are overwriting the MultiplayerAPI of the root.
func _process(_delta: float):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
