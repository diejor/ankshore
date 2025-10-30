class_name GameServer
extends Node

@export var port = 21253

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := WebSocketMultiplayerPeer.new()

@onready var crypto := Crypto.new()
@onready var tls_key := crypto.generate_rsa(2048)
@onready var cert := crypto.generate_self_signed_certificate(tls_key, "CN=localhost,O=MyOrganisation,C=US")

func _ready():
	if "--server" in OS.get_cmdline_args():
		init()
	
	var cert_path = "res://server_cert.crt"
	cert.save(cert_path)
	
	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.peer_disconnected.connect(on_peer_disconnected)

func init() -> Error:
	var tls_server_options: TLSOptions = TLSOptions.server(tls_key, cert)
	var creation_result: Error = multiplayer_peer.create_server(port, "*", tls_server_options)
	
	if creation_result == ERR_CANT_CREATE:
		push_warning("Most likely port is not available.")
		return creation_result
	
	config_api()
	print("Server ready on ", "*", ":", port)
	
	return creation_result

func on_peer_connected(peer_id: int) -> void:
	var msg = "Hello to client %d, by: %d" % [peer_id, multiplayer_peer.get_unique_id()]
	$TestRPC.rpc_send_message.rpc_id(peer_id,  msg)
	
	$Players/PlayerSpawner.spawn(peer_id)

func on_peer_disconnected(peer_id: int) -> void:
	for child in $Players.get_children():
		if int(child.name) == peer_id:
			child.queue_free()


func config_api():
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())

# We need to manually poll because we are overwriting the MultiplayerAPI of the root.
func _process(_delta: float):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
