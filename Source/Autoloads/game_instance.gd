class_name GameInstanceType
extends Node

var _bootstrapped := false
var offline_mode := false

func _ready() -> void:
	_bootstrap_network()

func connect_client(server_address: String, username: String) -> Error:
	var client_err: Error = Client.init(server_address, username)
	if client_err == OK:
		offline_mode = false
	else:
		offline_mode = true
	return client_err
	
func is_online() -> bool:
	return not offline_mode and (is_server() or is_client())

func is_server() -> bool:
	var peer := Server.multiplayer_api.multiplayer_peer
	return peer != null and peer is not OfflineMultiplayerPeer and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

func is_client() -> bool:
	var peer := Client.multiplayer_api.multiplayer_peer
	return peer != null and peer is not OfflineMultiplayerPeer and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

func _bootstrap_network() -> void:
	if _bootstrapped:
		return

	_bootstrapped = true

	if OS.has_feature("web"):
		offline_mode = true
		return

	if "--server" in OS.get_cmdline_args():
		var dedicated_err := Server.init()
		assert(dedicated_err == OK,
			"Dedicated server failed to start: %s" % error_string(dedicated_err))
		offline_mode = false
		return

	var server_err: Error = Server.init()
	if server_err != OK and server_err != ERR_ALREADY_IN_USE:
		push_warning("Local server bootstrap failed: %s" % error_string(server_err))

	var username := _default_username()
	var client_err: Error = Client.init("localhost", username)
	if client_err != OK:
		push_warning("Local client bootstrap failed: %s" % error_string(client_err))
		offline_mode = true
	else:
		offline_mode = false

func _default_username() -> String:
	var candidate := OS.get_environment("USERNAME")
	if candidate.is_empty():
		return "player"
	return candidate
