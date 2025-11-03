extends Node

@onready var scene_manager := $"/root/GameInstance/SceneManager"

var tp_destination := ""

func _ready() -> void:
	scene_manager.child_entered_tree.connect(on_scene_changed)

func begin_teleport(_tp_destination: String) -> void:
	tp_destination = _tp_destination
	
	# tp the player far from tp area while the scene is changing
	get_parent().global_position.y += 999999999

func on_scene_changed(_node: Node) -> void:
	var tp_path := "%" + tp_destination + "/Marker2D"
	var tp_node = scene_manager.current_scene.get_node_or_null(tp_path)
	if tp_node:
		get_parent().global_position = tp_node.global_position
		get_parent().get_node("Camera2D").reset_smoothing()
