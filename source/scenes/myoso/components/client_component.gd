class_name ClientComponent
extends Node

@export var is_active: IsActive

@onready var autoload_signals: AutoloadSignals = %AutoloadSignals
@onready var player_spawner: PlayerSpawner = owner.get_parent().get_node("%PlayerSpawner")


func _ready() -> void:
	if not GameInstance.is_client():
		push_warning("Running without an active client")

	# Remove offline players and replace them with a player scene.
	assert(not is_active.resource_local_to_scene,
		("In order to detect active players, `%s` resource must NOT be local" +
		"to scene.") % is_active,
	)
	var offline_name := owner.name
	var offline_node: Node = owner.get_node_or_null("%" + offline_name)
	if not is_active.active:
		is_active.active = true
		await autoload_signals.scene_changed
		Client.connected_to_server.emit()
		return

	if offline_node != null:
		offline_node.queue_free()


## When the client connects, we need to let the server know to spawn us, `PlayerSpawner`
## will replicate us back.
func on_connected_to_server() -> void:
	assert(GameInstance.is_client())
	var player_data: Dictionary = {
		username = Client.username,
		peer_id = Client.uid,
	}

	owner.queue_free()
	player_spawner.request_spawn_player.rpc_id(1, player_data)
