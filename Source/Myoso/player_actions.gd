class_name PlayerActions
extends Resource

signal action_changed(action: StringName, pressed: bool)

@export_custom(PROPERTY_HINT_INPUT_NAME, &"property") var move_left: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"property") var move_right: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"property") var move_up: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"property") var move_down: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"property") var sprint: StringName

var state: Dictionary[StringName, bool]

var direction_state := Vector2.ZERO
var sprinting_state := false

func _init() -> void:
	ready.call_deferred()
	
func ready() -> void:
	if not resource_local_to_scene:
		push_warning("The 'actions' resource is not local. Meaning that other nodes
		can modify the owner's actions. If you don't want this behavior, go to the
		resource and enable `resource_local_to_scene` through the inspector.")

func assert_action(action: StringName) -> void:
	assert(InputMap.has_action(action), "Missing InputMap action: %s." % action)
	
func build_state_dict():
	for property in get_property_list():
		if property.hint_string == &"property":
			var action_name = property.name
			assert_action(action_name)
			state[action_name] = false

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_echo():
		return

	for action: StringName in state.keys():
		if event.is_action_pressed(action):
			if state[action] != true:
				state[action] = true
				action_changed.emit(action, state[action])
		elif event.is_action_released(action):
			if state[action] != false:
				state[action] = false
				action_changed.emit(action, state[action])

func update_action_states(_delta: float) -> void:
	direction_state = get_vector2(
		move_left,
		move_right,
		move_up,
		move_down
	)
	
	sprinting_state = is_down(sprint)

func is_down(action: StringName) -> bool:
	assert_action(action)
	return state[action]

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
