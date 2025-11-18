extends RefCounted

class_name SaveBackend

func save(_slot_name: String, _snapshot: Dictionary) -> Error:
	return ERR_UNAVAILABLE

func load(_slot_name: String) -> Dictionary:
	return {}
