class_name GameClient
extends Node

@export var port = 21253

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := WebSocketMultiplayerPeer.new()


func _ready():
	if "--server" in OS.get_cmdline_args():
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	multiplayer_api.peer_connected.connect(on_peer_connected)

func init(server_address: String):
	var cert := X509Certificate.new()
	var cert_path = "res://server_cert.crt"
	cert.load(cert_path)
	var tls_client_options := TLSOptions.client(cert)
	var creation_result = multiplayer_peer.create_client("wss://" + server_address + ":" + str(port), tls_client_options)
	
	if creation_result != OK:
		push_warning("Can't create client: " + str(creation_result))
		return creation_result
		

	config_api()
	print("Client connecting to ", server_address, ":", port)

func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, multiplayer_peer.get_unique_id()]
	$TestRPC.rpc_send_message.rpc_id(peer_id, msg)


func config_api():
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())

# We need to manually poll because we are overwriting the MultiplayerAPI of the root.
func _process(_delta: float):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
