extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player

func spawn_player(player_data: Dictionary):
	var player = player_scene.instantiate()
	player.propagate_call("on_player_data", [player_data])
	player.set_multiplayer_authority(player_data.peer_id)
	player.name = str(player_data.peer_id)
	return player

@rpc("any_peer", "call_remote")
func request_spawn(data):
	spawn(data)
