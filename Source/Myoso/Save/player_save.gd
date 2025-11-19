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
