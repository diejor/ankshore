class_name GameInstanceType
extends Node

const UID_CACHE_PATH := "res://.godot/uid_cache.bin"

var _uid_by_path: Dictionary = {}
var _uid_loaded := false
var _tried_loading := false
var _bootstrapped := false
var offline_mode := false

func _ready() -> void:
	_load_uid_cache_once()
	_bootstrap_network()

func _load_uid_cache_once() -> void:
	if _uid_loaded or _tried_loading:
		return
	_tried_loading = true

	if Engine.is_editor_hint():
		_uid_loaded = true
		return

	var f := FileAccess.open(UID_CACHE_PATH, FileAccess.READ)
	if f == null:
		push_warning("UID cache not found at %s (export should include it)." % UID_CACHE_PATH)
		_uid_loaded = true
		return

	var count := f.get_32()
	for i in count:
		var id := f.get_64()
		var _len := f.get_32()
		var buf := f.get_buffer(_len)
		var path := buf.get_string_from_utf8()
		_uid_by_path[path] = id
	_uid_loaded = true

func get_uid_from_path(path: String) -> int:
	if path.is_empty():
		return ResourceUID.INVALID_ID

	var uid_text := ResourceUID.path_to_uid(path)
	if uid_text.begins_with(&"uid://"):
		return ResourceUID.text_to_id(uid_text)

	_load_uid_cache_once()
	@warning_ignore("unsafe_call_argument")
	return int(_uid_by_path.get(path, ResourceUID.INVALID_ID))

func get_uid_from_node(node: Node) -> int:
	if node == null:
		return ResourceUID.INVALID_ID
	return get_uid_from_path(node.scene_file_path)

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
