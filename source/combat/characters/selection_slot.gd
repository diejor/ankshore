@tool
class_name SelectionSlot extends Control

## Manages positioning and focus control for a character in combat.

@export var focus_on_ready: bool = false

## The combat character currently assigned to this slot.
var selected: Node:
	set(node):
		selected = node
		if not selected.is_inside_tree():
			push_error("Trying to select a node not inside the tree.")
			return
		selected.reparent.call_deferred(self)


func _ready() -> void:
	if focus_on_ready:
		grab_focus.call_deferred()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Handle character select action
	if has_focus and Input.is_action_just_pressed("select_character"):
		print("input character selected!")


# Updates process mode when focus enters.
func _on_focus_entered() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	if not selected is Character:
		print("No character found in slot")


# Updates process mode when focus exits.
func _on_focus_exited() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


# Triggered when child is added to slot. Defer alignment correction.
func _on_child_entered(node: Node) -> void:
	_correct_pos.call_deferred(node)


# Synchronizes the child's global position to match the slot.
func _correct_pos(node: Node) -> void:
	@warning_ignore("unsafe_property_access")
	node.global_position = global_position
