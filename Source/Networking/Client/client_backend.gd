extends Resource
class_name MultiplayerClientBackend

## Base class for client-side transports (WebSocket, WebRTC, Offline, etc.)

var multiplayer_api := SceneMultiplayer.new()
var multiplayer_peer: MultiplayerPeer

func create_connection(_server_address: String, _username: String) -> Error:
	## Implement in subclasses.
	return ERR_UNAVAILABLE

func configure_tree(tree: SceneTree, root_path: NodePath) -> void:
	## Set this backend's MultiplayerAPI for the given subtree.
	multiplayer_api.multiplayer_peer = multiplayer_peer
	multiplayer_api.root_path = root_path
	tree.set_multiplayer(multiplayer_api, root_path)

func poll(_dt: float) -> void:
	## Called by GameClient._process.
	if multiplayer_api and multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()

func peer_reset_state() -> void:
	## Optional override in concrete backends.
	multiplayer_peer = null
	multiplayer_api.multiplayer_peer = null

func get_unique_id() -> int:
	return multiplayer_api.get_unique_id()

func has_peer() -> bool:
	return multiplayer_api.has_multiplayer_peer()
