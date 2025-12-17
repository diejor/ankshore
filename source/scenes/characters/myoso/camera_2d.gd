extends Camera2D

func _ready() -> void:
	var should_remove: bool = not is_multiplayer_authority() or multiplayer.is_server()
	if should_remove:
		queue_free()
