extends Camera2D

func _ready() -> void:
	if not is_multiplayer_authority() or multiplayer.is_server():
		queue_free()
