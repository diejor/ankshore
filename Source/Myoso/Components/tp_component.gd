extends Node

signal begin_tp()
signal finished_tp()

@onready var owner2d: Node2D = owner as Node2D
var tp_destination: String = ""

func begin_teleport(_tp_destination: String) -> void:
	assert(not _tp_destination.is_empty(), "Teleporting to an unnamed `TPArea` is not valid.")
	begin_tp.emit()
	# Store `tp_destination`, wait for `on_scene_changed` to be called
	tp_destination = _tp_destination
	
	# Move the player far from tp area before the scene changes,
	# fixes the bug of phantom `body_entered` signals after player already teleported.
	owner2d.global_position.y += 999999999

## If `on_scene_changed` was called it probably means the player is trying to teleport.
## A player will actually teleport to a `TPArea` if they called `begin_teleport` before 
## switching the scene.
func on_scene_changed(current_scene: Node) -> void:
	var tp_path: String = "%" + tp_destination + "/Marker2D"
	var tp_node: Marker2D = current_scene.get_node_or_null(tp_path)
	if tp_node:
		owner2d.global_position = tp_node.global_position
		var camera: Camera2D = owner.get_node("Camera2D")
		camera.reset_smoothing()
		finished_tp.emit()
