class_name FileSaveBackend
extends SaveBackend

const JSON_INDENT := "\t"
var INVALID_FILENAME_CHARS := PackedStringArray(["/", "\\", ":", "*", "?", "\"", "<", ">", "|"])

@export var base_dir := "user://saves"

func save(slot_name: String, snapshot: Dictionary) -> Error:
	var result := _ensure_directory()
	if result != OK:
		return result
	var file := FileAccess.open(_slot_path(slot_name), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot, JSON_INDENT))
	return OK

func load(slot_name: String) -> Dictionary:
	var path := _slot_path(slot_name)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}

func _ensure_directory() -> Error:
	var absolute := ProjectSettings.globalize_path(base_dir)
	var result := DirAccess.make_dir_recursive_absolute(absolute)
	if result == ERR_ALREADY_EXISTS:
		return OK
	return result

func _slot_path(slot_name: String) -> String:
	var prefix := base_dir
	if not prefix.ends_with("/"):
		prefix += "/"
	return "%s%s.json" % [prefix, _sanitize_slot_name(slot_name)]

func _sanitize_slot_name(name: String) -> String:
	var sanitized := name.strip_edges()
	if sanitized.is_empty():
		sanitized = "slot"
	for _char in INVALID_FILENAME_CHARS:
		sanitized = sanitized.replace(_char, "_")
	sanitized = sanitized.replace(" ", "_")
	if sanitized.is_empty():
		sanitized = "slot"
	return sanitized.to_lower()
