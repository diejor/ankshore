extends Button
@export var winterScene: PackedScene

func _on_pressed() -> void:
	
	print("hello Ankshore")
	get_tree().change_scene_to_packed(winterScene)
	
