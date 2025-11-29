class_name ClientComponent
extends Node

## The client component works closely with the client peer instanciated at 
## `GameInstance.client` to make this player controller have a network connection.

@onready var player_spawner: PlayerSpawner = owner.get_parent().get_node("%PlayerSpawner")

func _ready() -> void:
	if not GameInstance.is_client():
		push_warning("ClientComponent running without an active client; network features are offline.")


## When the client connects, we need to let the server know to spawn us, `PlayerSpawner` 
## will replicate us back.
func on_connected_to_server() -> void:
	assert(GameInstance.is_client(),
		"`on_connected_to_server` called while the client is offline.")
	var player_data: Dictionary = {
		username = Client.username,
		peer_id = Client.uid
	}
	
	owner.queue_free()
	player_spawner.request_spawn_player.rpc_id(1, player_data)
	
