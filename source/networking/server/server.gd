class_name GameServer
extends Node

@export var port := 21253

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer := WebSocketMultiplayerPeer.new()

func _ready():
	if OS.has_feature("web"):
		return
	if "--server" in OS.get_cmdline_args():
		init()
		%Wolf.queue_free()

	multiplayer_api.peer_connected.connect(on_peer_connected)
	multiplayer_api.peer_disconnected.connect(on_peer_disconnected)

func init() -> Error:
	var err := multiplayer_peer.create_server(port)
	if err != OK:
		push_warning("create_server failed: %s" % str(err))
		return err
	config_api()
	print("Server ready on *:%d" % port)
	return OK

func on_peer_connected(id:int) -> void:
	$TestRPC.rpc_send_message.rpc_id(id, "Hello from %d" % multiplayer_peer.get_unique_id())

func on_peer_disconnected(id:int) -> void:
	for child in $Players.get_children():
		if int(child.name) == id:
			child.queue_free()

func config_api():
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = get_path()
	get_tree().set_multiplayer(multiplayer_api, get_path())

func _process(_dt):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()
