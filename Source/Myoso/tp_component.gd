extends Node

var tp_destination := ""

func _ready() -> void:
	GameInstance.scene_manager.scene_changed.connect(on_scene_changed)

func begin_teleport(_tp_destination: String) -> void:
	tp_destination = _tp_destination
	
	# Tp the player far from tp area before the scene changes,
	# Fixes the bug of phantom body_entered after player teleported.
	get_parent().global_position.y += 999999999

func on_scene_changed(current_scene: Node) -> void:
	var tp_path := "%" + tp_destination + "/Marker2D"
	var tp_node = current_scene.get_node_or_null(tp_path)
	if tp_node:
		get_parent().global_position = tp_node.global_position
		get_parent().get_node("Camera2D").reset_smoothing()
