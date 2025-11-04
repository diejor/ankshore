class_name SceneManager
extends Node2D

@onready var current_scene_path: NodePath
@export_file var empty_scene: String

var current_scene: Node

func _ready() -> void:
	reparent_current_scene()
	if "--server" in OS.get_cmdline_args():
		get_tree().change_scene_to_file.call_deferred(empty_scene)
	
	get_tree().scene_changed.connect(on_scene_changed)

func on_scene_changed():
	var previous_scene = get_node_or_null(current_scene_path)
	if previous_scene:
		previous_scene.queue_free()
		
	reparent_current_scene()

func reparent_current_scene():
	var new_scene := get_tree().current_scene
	current_scene_path = NodePath(new_scene.name)
	current_scene = new_scene
	new_scene.reparent.call_deferred($".")
