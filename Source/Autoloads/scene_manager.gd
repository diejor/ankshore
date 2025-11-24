class_name SceneManagerClass
extends Node2D

signal scene_changed(current_scene: Node, old_scene: Node)

var current_scene_path: NodePath
var current_scene: Node
var previous_scene_to_clean: Node

func _ready() -> void:
	y_sort_enabled = true
	reparent_current_scene()
	if "--server" in OS.get_cmdline_args():
		pass
	
	get_tree().scene_changed.connect(on_scene_changed)

func on_scene_changed() -> void:
	previous_scene_to_clean = get_node_or_null(current_scene_path)
		
	reparent_current_scene()

func reparent_current_scene() -> void:
	var new_scene := get_tree().current_scene
	current_scene_path = NodePath(new_scene.name)
	current_scene = new_scene
	reparent_with_signal.call_deferred(new_scene, $".")

func reparent_with_signal(node: Node, new_parent: Node) -> void:
	if previous_scene_to_clean:
		previous_scene_to_clean.queue_free.call_deferred()
	node.reparent(new_parent)
	scene_changed.emit(node, previous_scene_to_clean)
