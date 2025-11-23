@tool
## ResourceFormatLoader for DictionaryResource.
## - .tdict: loads JSON into DictionaryResource.
## - .dict:  loads store_var() binary into DictionaryResource.
class_name DictionaryResourceFormatLoader
extends ResourceFormatLoader

const TEXT_EXT := "tdict"
const BIN_EXT  := "dict"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray([TEXT_EXT, BIN_EXT])


func _handles_type(type: StringName) -> bool:
	return type == &"Resource" or type == &"DictionaryResource" or type == &"DataResource"


func _get_resource_type(path: String) -> String:
	var ext := path.get_extension().to_lower()
	if ext == TEXT_EXT or ext == BIN_EXT:
		return "DictionaryResource"
	return ""


func _recognize_path(path: String, type: StringName) -> bool:
	var ext := path.get_extension().to_lower()
	if ext != TEXT_EXT and ext != BIN_EXT:
		return false

	if type != StringName():
		return _handles_type(type)

	return true


func _exists(path: String) -> bool:
	return FileAccess.file_exists(path)


func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var ext := path.get_extension().to_lower()
	assert(ext == TEXT_EXT or ext == BIN_EXT, "`DictionaryResourceFormatLoader` given unsupported extension: %s" % ext)

	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Failed to open file in `DictionaryResourceFormatLoader._load().`")
	if file == null:
		return FileAccess.get_open_error()

	var dict_res := DictionaryResource.new()

	if ext == TEXT_EXT:
		var text := file.get_as_text()

		var json := JSON.new()
		var err := json.parse(text)
		assert(err == OK, "JSON parse failed for `DictionaryResource` `\"*.tdict\"`. Error: %s" % error_string(err))

		var decoded: Dictionary[StringName, Variant] = JSON.to_native(json.data, false)

		dict_res.data = decoded
	else:
		assert(ext == BIN_EXT)
		if file.get_length() == 0:
			return ERR_FILE_CORRUPT

		var decoded: Variant = file.get_var()
		assert(typeof(decoded) == TYPE_DICTIONARY, "Binary `\"*.dict\"` did not contain a Dictionary for DictionaryResource.")
		if typeof(decoded) != TYPE_DICTIONARY:
			return ERR_FILE_CORRUPT

		dict_res.data = decoded
	
	dict_res.save_format = DictionaryResource.SaveFormat.TEXT if ext == TEXT_EXT else DictionaryResource.SaveFormat.BINARY
	dict_res.take_over_path(path)
	return dict_res
