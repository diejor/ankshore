class_name SceneManagerClass
extends Node2D

signal scene_changed(current_scene: Node, old_scene: Node)


var lobby_manager: LobbyManager:
	get: return get_node("LobbyManager")


var current_scene_path: NodePath
var current_scene: Node

var previous_scene_to_clean: Node
var teleporting: bool


func _ready() -> void:
	var lobby_scene: PackedScene = load("uid://c6uoacg4w1nox")
	var lobby_node: Node = lobby_scene.instantiate()
	add_child(lobby_node)
	y_sort_enabled = true
	reparent_current_scene()
	if "--server" in OS.get_cmdline_args():
		pass
	
	get_tree().scene_changed.connect(on_scene_changed)

func teleport(caller: Node) -> void:
	teleporting = true
	caller.tree_exited.connect(finish_teleport)

func finish_teleport() -> void:
	teleporting = false
	if previous_scene_to_clean:
		previous_scene_to_clean.queue_free()

func on_scene_changed() -> void:
	previous_scene_to_clean = get_node_or_null(current_scene_path)
		
	reparent_current_scene()

func reparent_current_scene() -> void:
	var new_scene := get_tree().current_scene
	current_scene_path = NodePath(new_scene.name)
	current_scene = new_scene
	reparent_with_signal.call_deferred(new_scene, $".")

func reparent_with_signal(node: Node, new_parent: Node) -> void:
	node.reparent(new_parent)
	scene_changed.emit(node, previous_scene_to_clean)

	if not teleporting and previous_scene_to_clean:
		previous_scene_to_clean.queue_free.call_deferred()
