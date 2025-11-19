class_name PlayerSave
extends DataResource

@export_custom(PROPERTY_HINT_NONE, &"data") var current_scene_uid := -1:
	set(value):
		current_scene_uid = value
		state_dict.current_scene_uid = value
		emit_changed()
		
@export_custom(PROPERTY_HINT_NONE, &"data") var position: Vector2 = Vector2.ZERO:
	set(value):
		position = value
		state_dict.position = value
		emit_changed()

func _build_properties_array() -> void:
	assert(properties.is_empty(), "Probably this `DataResource` is shared when 
	is expected to not be shared. ")
	
	for property in get_property_list():
		if property.hint_string == &"data":
			properties.append(property.name)
	
	assert(not properties.is_empty())
