class_name InputComponent
extends Node

# Handles input through `_unhandled_input` function. Used instead of `Input` singleton
# to allow GUI to capture input and not leak through the character controller.

signal action_changed(action: StringName, pressed: bool)

@export var actions: PlayerActions

func _ready() -> void:
	if not is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	assert(actions, "`InputComponent` must have an `actions` resource to update.")
	push_warning(actions != owner.actions, "A little bit weird that `InputComponent`
	doesn't have the same `actions` resource as the player.")
	
	actions.build_state_dict()
	actions.action_changed.connect(on_action_changed)

func _physics_process(_delta: float) -> void:
	actions.update_action_states(_delta)

func _unhandled_input(event: InputEvent) -> void:
	actions.handle_input(event)

func on_action_changed(action: StringName, pressed: bool):
	action_changed.emit(action, pressed)
