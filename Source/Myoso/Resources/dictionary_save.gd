@tool
## Resource that stores arbitrary key/value pairs in a Dictionary.
class_name DictionarySave
extends SaveContainer

@export var data: Dictionary[StringName, Variant] = {}


func set_value(property: StringName, value: Variant) -> void:
	data[property] = value


func get_value(property: StringName, default: Variant = null) -> Variant:
	return data.get(property, default)


func has_value(property: StringName) -> bool:
	return data.has(property)

func from_bytes(bytes: PackedByteArray) -> void:
	data = bytes_to_var(bytes)
	
func to_bytes() -> PackedByteArray:
	return var_to_bytes(data)

## Saves this DictionarySave using ResourceSaver.
## save_slot is a base path with no extension; extension is chosen from save_format.
func save_state(save_slot: String) -> Error:
	var err := ResourceSaver.save(self, save_slot)
	assert(err == OK, 
		"Failed to save `%s`. Error: %s" % [save_slot, error_string(err)])
	return err


## Loads a DictionarySave from disk using ResourceLoader.
## save_slot is a base path with no extension; only the extension implied by save_format is tried.
func load_state(save_slot: String) -> Error:
	if not ResourceLoader.exists(save_slot, "DictionarySave"):
		push_warning("No `DictionarySave` file found at path: 
			%s" % save_slot)
		return ERR_FILE_NOT_FOUND

	var res := ResourceLoader.load(save_slot, "DictionarySave")
	assert(res != null, "`ResourceLoader.load` returned null for %s." % save_slot)
	if res == null:
		return ERR_CANT_OPEN

	var dict_res := res as DictionarySave
	assert(dict_res != null, 
		"Loaded resource at %s is not a DictionarySave." % save_slot)
	if dict_res == null:
		return ERR_FILE_CORRUPT

	data = dict_res.data.duplicate(true)

	return OK


func get_property_names() -> Array[StringName]:
	return data.keys()
