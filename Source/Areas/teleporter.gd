extends Area2D

@export_file var scene_path: String
@export var target_tp_id: String

@onready var scene_manager: Node = $"/root/GameInstance/SceneManager"

func _on_body_entered(body: Node2D) -> void:
	var tp := body.get_node_or_null("TPComponent")
	if tp == null or not body.is_multiplayer_authority():
		return
		
	tp.begin_teleport(target_tp_id)
	get_tree().change_scene_to_file.call_deferred(scene_path)
