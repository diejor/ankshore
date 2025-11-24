class_name AreaTP
extends Area2D

@export_file var scene_path: String
@onready var scene_name: String = _get_scene_name(scene_path)

@export var target_tp_id: String



func _on_body_entered(body: Node2D) -> void:
	# Only teleport nodes that have a `TPComponent`
	var tp: TPComponent = body.get_node_or_null("%TPComponent")
	if tp == null or not tp.is_multiplayer_authority():
		return
	
	tp.begin_teleport(target_tp_id)
	get_tree().change_scene_to_file.call_deferred(scene_path)

func _get_scene_name(_scene_path: String) -> StringName:
	assert(FileAccess.file_exists(_scene_path), "`scene_path` must be valid to get a name from.")
	var packed_scene: PackedScene = load(_scene_path)
	var scene_state: SceneState = packed_scene.get_state()
	return scene_state.get_node_name(0)
