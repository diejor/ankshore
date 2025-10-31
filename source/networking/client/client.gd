class_name GameClient
extends Node

@export var port = 21253

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := ENetMultiplayerPeer.new()


func _ready():
	if "--server" in OS.get_cmdline_args():
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.connected_to_server.connect(on_connected_to_server)
	

func init(server_address: String):
	var creation_result = multiplayer_peer.create_client(server_address, port)
	
	if creation_result != OK:
		push_warning("Can't create client: " + str(creation_result))
		return creation_result

	config_api()
	set_multiplayer_authority(multiplayer_peer.get_unique_id(), false)
	print("Client connecting to ", server_address, ":", port)

func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, multiplayer_peer.get_unique_id()]
	$TestRPC.rpc_send_message.rpc_id(peer_id, msg)

func on_connected_to_server():
	var player: Wolf = %Wolf
	if player:
		var player_data = {
			peer_id=multiplayer_peer.get_unique_id(), 
			position=player.position
		}
		
		$Players/PlayerSpawner.request_spawn.rpc_id(1, player_data)
		player.queue_free()

func config_api():
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())

# We need to manually poll because we are overwriting the MultiplayerAPI of the root.
func _process(_delta: float):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
