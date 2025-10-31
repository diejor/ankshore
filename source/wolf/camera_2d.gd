extends Camera2D

func _ready() -> void:
	var multiplayer_api: SceneMultiplayer = multiplayer
	var root_path := ^"/root"
	if not is_multiplayer_authority() or multiplayer.is_server() and not multiplayer_api.root_path == root_path:
		queue_free()
