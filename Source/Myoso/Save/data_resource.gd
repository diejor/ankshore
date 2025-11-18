class_name DataResource
extends Resource

@export var properties: Array[StringName]
@export var state_dict: Dictionary

func _init() -> void:
	# Dynamic dispatch, meaning that the inherited function should be called
	# instead of the one defined in this file.
	_build_properties_array()

func on_data(data: Dictionary) -> void:
	assert(not properties.is_empty(), "Trying to use `properties` without calling 
	`_build_properties_array` first.")
	
	for property_name in properties:
		var to_replicate = data.get(property_name)
		assert(to_replicate, "Data given doesn't contain `%s`." % property_name)
		set(property_name, to_replicate)

func _build_properties_array() -> void:
	push_error("`_build_properties_array` should be implemented.")
