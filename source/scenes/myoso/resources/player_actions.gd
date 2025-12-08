class_name PlayerActions
extends ActionsResource

@export_custom(PROPERTY_HINT_INPUT_NAME, &"action") var move_left: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"action") var move_right: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"action") var move_up: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"action") var move_down: StringName
@export_custom(PROPERTY_HINT_INPUT_NAME, &"action") var sprint: StringName

func get_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for property in get_property_list():
		if property.hint_string == &"action":
			var action_name: StringName = property.name
			actions.append(action_name)
	return actions
