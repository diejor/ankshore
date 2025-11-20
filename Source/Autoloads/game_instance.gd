class_name GameInstanceType
extends Node

const UID_CACHE_PATH := "res://.godot/uid_cache.bin"

var _uid_by_path: Dictionary = {}
var _uid_loaded := false
var _tried_loading := false

func _ready() -> void:
	_load_uid_cache_once()

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
	
func is_online() -> bool:
	var _is_client: bool = Client.multiplayer_api.multiplayer_peer is not OfflineMultiplayerPeer
	var _is_server: bool = Server.multiplayer_api.multiplayer_peer is not OfflineMultiplayerPeer
	return _is_client or _is_server

func is_server() -> bool:
	return Server.multiplayer_api.multiplayer_peer is not OfflineMultiplayerPeer
