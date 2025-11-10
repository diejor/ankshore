extends Node

@onready var player: CharacterBody2D = $"../.."

var tp_destination := ""

func _ready() -> void:
	GameInstance.scene_manager.scene_changed.connect(on_scene_changed)

func begin_teleport(_tp_destination: String) -> void:
	assert(not _tp_destination.is_empty(), "Teleporting to an unnamed `TPArea` is not valid.")
	# Store `tp_destination`, wait for `on_scene_changed` to be called
	tp_destination = _tp_destination
	
	# Move the player far from tp area before the scene changes,
	# fixes the bug of phantom `body_entered` signals after player already teleported.
	player.global_position.y += 999999999

# If `on_scene_changed` was called it probably means the player is trying to teleport.
# A player will actually teleport to a `TPArea` if they called `begin_teleport` before 
# switching the scene.
func on_scene_changed(current_scene: Node) -> void:
	var tp_path := "%" + tp_destination + "/Marker2D"
	var tp_node = current_scene.get_node_or_null(tp_path)
	if tp_node:
		player.global_position = tp_node.global_position
		player.get_node("Camera2D").reset_smoothing()
