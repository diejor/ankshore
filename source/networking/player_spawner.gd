extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player

func spawn_player(peer_id: int) -> Wolf:
	var wolf: Wolf = player_scene.instantiate()
	wolf.position = 100.*Vector2(randf(), randf())
	wolf.set_multiplayer_authority(peer_id)
	wolf.name = str(peer_id)
	return wolf
