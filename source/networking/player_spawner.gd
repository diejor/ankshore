extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player


func spawn_player(player_data: Dictionary) -> Wolf:
	var wolf: Wolf = player_scene.instantiate()
	wolf.position = player_data.position
	wolf.set_multiplayer_authority(player_data.peer_id)
	wolf.name = str(player_data.peer_id)
	return wolf

@rpc("any_peer", "call_remote")
func request_spawn(data):
	spawn(data)
