extends Node2D

func get_resource_uid(path: String) -> int:
	assert(path, "Resource path must be non-null to get a uid.")

	if path.is_empty():
		return ResourceUID.INVALID_ID
	
	var uid_text := ResourceUID.path_to_uid(path)
	if uid_text.begins_with(&"uid://"):
		return ResourceUID.text_to_id(uid_text)

	return ResourceUID.INVALID_ID
	
func is_online() -> bool:
	return get_node("%Network/%GameClient").get_multiplayer_authority() != 1
