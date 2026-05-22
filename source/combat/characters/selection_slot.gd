@tool
class_name SelectionSlot extends Control

## Focusable container for a [Character], gated by a [enum StepMode].
##
## Pure presentation: planning steps toggle the slot's focusability via
## [method set_step_mode]; controllers ([PlayerController]) decide when
## the focused slot is committed. The slot itself does not poll input.

## How the slot responds to focus traversal.
## [br]- [code]INERT[/code]: not focusable.
## [br]- [code]SELECTABLE_OWN[/code]: focusable as one of "my" team's
## characters (character selection).
## [br]- [code]SELECTABLE_TARGET[/code]: focusable as a target of
## another character's action.
enum StepMode {
	INERT,
	SELECTABLE_OWN,
	SELECTABLE_TARGET,
}

@export var focus_on_ready: bool = false

## The combat character currently assigned to this slot.
var selected: Node:
	set(node):
		selected = node
		if not selected.is_inside_tree():
			push_error("Trying to select a node not inside the tree.")
			return
		selected.reparent.call_deferred(self)

var step_mode: StepMode = StepMode.INERT


func _ready() -> void:
	set_step_mode(step_mode)
	if focus_on_ready:
		grab_focus.call_deferred()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


## Sets the slot's selection mode and toggles [member focus_mode]
## accordingly. Slots in [code]INERT[/code] mode cannot grab focus.
func set_step_mode(mode: StepMode) -> void:
	step_mode = mode
	focus_mode = (
		Control.FOCUS_ALL if mode != StepMode.INERT
		else Control.FOCUS_NONE
	)


## Returns the [Character] currently parented to this slot, or
## [code]null[/code] if the slot is empty.
func get_character() -> Character:
	return selected as Character


# Updates process mode when focus enters.
func _on_focus_entered() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT


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
