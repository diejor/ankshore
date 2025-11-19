extends Node

@export var peer: String

@rpc("any_peer")
func rpc_send_message(msg: String) -> void:
	print("Message received on %s: " % peer, msg)
