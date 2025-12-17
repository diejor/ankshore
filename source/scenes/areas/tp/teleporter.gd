class_name AreaTP
extends Area2D

@export_file var scene_path: String
var scene_name: String:
	get: return TPComponent.get_scene_name(scene_path)

@export var target_tp_id: String


func _on_body_entered(body: Node2D) -> void:
	# Only teleport nodes that have a `TPComponent`
	var tp: TPComponent = body.get_node_or_null("%TPComponent")
	if tp == null or not tp.is_multiplayer_authority():
		return
		
	tp.begin_teleport(target_tp_id, scene_path)
