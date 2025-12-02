class_name GameInstanceType
extends Node

func is_online() -> bool:
	return is_server() or is_client()

func is_server() -> bool:
	var peer: MultiplayerPeer = Server.multiplayer_api.multiplayer_peer
	return (peer != null 
		and peer is not OfflineMultiplayerPeer 
		and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED)

func is_client() -> bool:
	var peer: MultiplayerPeer = Client.multiplayer_api.multiplayer_peer
	return (peer != null 
		and peer is not OfflineMultiplayerPeer 
		and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED)

func default_username() -> String:
	var candidate := OS.get_environment("USERNAME")
	if candidate.is_empty():
		return "player"
	return candidate
