class_name DataResource
extends Resource

var properties: Array[StringName]
var state_dict: Dictionary

func _init() -> void:
	build_properties_array()


func on_data(data: DataResource) -> void:
	assert(not properties.is_empty(), "Trying to use `properties` without calling 
	`_build_properties_array` first.")
	
	for property_name in properties:
		var to_replicate: Variant = data.get(property_name)
		assert(to_replicate, "Data given doesn't contain `%s`." % property_name)
		set(property_name, to_replicate)

func build_properties_array() -> void:
	assert(properties.is_empty(), "Probably this `DataResource` is shared when 
	is expected to not be shared. ")
	
	for property in get_property_list():
		if property.hint_string == &"data":
			properties.append(property.name)
	
	assert(not properties.is_empty(), "`properties` array is empty when it is expected 
	to have properties. Probably because the custom properties are not marked with 
	`data` through the `hint_string` of `@export_custom`")
