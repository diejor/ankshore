@tool
## Resource that stores arbitrary key/value pairs in a Dictionary.
class_name DictionaryResource
extends DataResource

const TEXT_EXT := "tdict"
const BIN_EXT  := "dict"

enum SaveFormat { TEXT, BINARY }

## Controls whether save_state/load_state use JSON (.tdict) or binary (.dict) as the primary format.
@export var save_format: SaveFormat = SaveFormat.BINARY

@export var data: Dictionary[StringName, Variant] = {}


func set_value(property: StringName, value: Variant) -> void:
	data[property] = value


func get_value(property: StringName, default: Variant = null) -> Variant:
	return data.get(property, default)


func has_value(property: StringName) -> bool:
	return data.has(property)


func replicate(delta: DataResource) -> void:
	var other := delta as DictionaryResource
	assert(other != null, "DictionaryResource.replicate() expects a DictionaryResource delta.")
	if other == null:
		return

	for key: StringName in other.data.keys():
		data[key] = other.data[key]


func get_state() -> DataResource:
	var clone := DictionaryResource.new()
	clone.data = data.duplicate(true)
	return clone


## Saves this DictionaryResource using ResourceSaver.
## save_slot is a base path with no extension; extension is chosen from save_format.
func save_state(save_slot: String) -> Error:
	var given_ext := save_slot.get_extension()
	assert(given_ext == "", "save_state expects base path without extension, got: .%s" % given_ext)
	if given_ext != "":
		return ERR_INVALID_PARAMETER

	var chosen_ext := TEXT_EXT if save_format == SaveFormat.TEXT else BIN_EXT
	var full_path := "%s.%s" % [save_slot, chosen_ext]

	var err := ResourceSaver.save(self, full_path)
	assert(err == OK, "Failed to save `DictionaryResource`. Error: %s" % error_string(err))
	return err


## Loads a DictionaryResource from disk using ResourceLoader.
## save_slot is a base path with no extension; only the extension implied by save_format is tried.
func load_state(save_slot: String) -> Error:
	var given_ext := save_slot.get_extension()
	assert(given_ext == "", "load_state expects base path with no extension, got: .%s" % given_ext)
	if given_ext != "":
		return ERR_INVALID_PARAMETER

	var ext := TEXT_EXT if save_format == SaveFormat.TEXT else BIN_EXT
	var full_path := "%s.%s" % [save_slot, ext]

	if not ResourceLoader.exists(full_path, "DictionaryResource"):
		push_warning("No .%s file found for base path: %s" % [ext, save_slot])
		return ERR_FILE_NOT_FOUND

	var res := ResourceLoader.load(full_path, "DictionaryResource")
	assert(res != null, "ResourceLoader.load returned null for %s." % full_path)
	if res == null:
		return ERR_CANT_OPEN

	var dict_res := res as DictionaryResource
	assert(dict_res != null, "Loaded resource at %s is not a DictionaryResource." % full_path)
	if dict_res == null:
		return ERR_FILE_CORRUPT

	data = dict_res.data.duplicate(true)

	save_format = SaveFormat.TEXT if ext == TEXT_EXT else SaveFormat.BINARY

	return OK


func get_property_names() -> Array[StringName]:
	return data.keys()
