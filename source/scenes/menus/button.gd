extends Button
@export var winterScene: PackedScene

func _ready() -> void:
	disabled = true

func _on_pressed() -> void:
	get_tree().change_scene_to_packed(winterScene)
	

func on_connected_to_server() -> void:
	disabled = false
