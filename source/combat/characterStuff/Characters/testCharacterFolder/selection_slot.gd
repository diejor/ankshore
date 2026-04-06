@tool
class_name SelectionSlot
extends Control

@export var focus_on_ready: bool = false

var selected: Node:
	set(node):
		selected = node
		if not selected.is_inside_tree():
			push_error("Trying to select a node not inside the tree.")
			return
		
		selected.reparent.call_deferred(self)

func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func _on_focus_entered() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT

func _on_focus_exited() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	if focus_on_ready:
		grab_focus.call_deferred()

func _on_child_entered(node: Node) -> void:
	_correct_pos.call_deferred(node)


func _correct_pos(node: Node) -> void:
	@warning_ignore("unsafe_property_access")
	node.global_position = global_position
