class_name InputComponent
extends Node

# Handles input through `_unhandled_input` function. Used instead of `Input` singleton
# to allow GUI to capture input and not leak through the character controller.

@export var state: Dictionary[StringName, bool] = {
	"move_left":  false,
	"move_right": false,
	"move_up":    false,
	"move_down":  false,
	"sprint":     false,
}

signal action_changed(action: StringName, pressed: bool)

func assert_action(action: StringName) -> void:
	assert(InputMap.has_action(action), "Missing InputMap action: %s" % action)

func _ready() -> void:
	for action: StringName in state.keys():
		assert_action(action)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_echo():
		return

	for action: StringName in state.keys():
		if event.is_action_pressed(action):
			if state[action] != true:
				state[action] = true
				action_changed.emit(action, true)
		elif event.is_action_released(action):
			if state[action] != false:
				state[action] = false
				action_changed.emit(action, false)

func is_down(action: StringName) -> bool:
	assert_action(action)
	return state.get(action)

func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	assert_action(negative_action)
	assert_action(positive_action)
	
	var p_action = 1.0 if is_down(positive_action) else 0.0
	var n_action = 1.0 if is_down(negative_action) else 0.0
	return p_action - n_action

func get_vector2(left: StringName, right: StringName, up: StringName, down: StringName) -> Vector2:
	assert_action(left)
	assert_action(right)
	assert_action(up)
	assert_action(down)

	var v := Vector2(get_axis(left, right), get_axis(up, down))
	return v if v.is_zero_approx() else v.normalized()
