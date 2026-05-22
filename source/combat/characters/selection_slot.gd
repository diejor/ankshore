@tool
class_name SelectionSlot extends Control

## Focusable container for a [Character], gated by a [enum StepMode].
##
## A planning step controls when a slot is interactive by calling
## [method set_step_mode]. While selectable, pressing
## [code]select_character[/code] emits [signal user_selected].

## How the slot responds to user input.
## [br]- [code]INERT[/code]: ignores focus and input.
## [br]- [code]SELECTABLE_OWN[/code]: picking the slot's own character
## (e.g. character selection during planning).
## [br]- [code]SELECTABLE_TARGET[/code]: picking the slot as a target
## of another character's action.
enum StepMode {
	INERT,
	SELECTABLE_OWN,
	SELECTABLE_TARGET,
}

## Fired when the focused slot accepts the [code]select_character[/code]
## input under a selectable [enum StepMode].
signal user_selected(slot: SelectionSlot)

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
	if focus_on_ready:
		grab_focus.call_deferred()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if (
		has_focus
		and step_mode != StepMode.INERT
		and Input.is_action_just_pressed("select_character")
	):
		user_selected.emit(self)


## Sets the slot's interaction mode and toggles [member focus_mode]
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
