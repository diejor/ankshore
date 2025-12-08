class_name SaveComponent
extends Node


signal instantiate
signal state_changed(caller: Node)


@export_dir var save_dir: String
@export var save_extension: String = ".tdict"
@export var save_container: SaveContainer
@onready var save_synchronizer: SaveSynchronizer:
	get:
		return get_child(0)

@onready var save_path: String:
	get:
		_prepare_save_dir()
		assert(
			save_extension.begins_with("."),
			"Save extension should begin with a dot.",
		)
		save_path = save_dir.path_join(owner.name + save_extension)

		assert(
			save_path.is_absolute_path(),
			"Invalid save to a not valid file path. " + save_path,
		)
		return save_path

func _init() -> void:
	instantiate.connect(_on_instantiate)

func _ready() -> void:
	assert(save_container)
	assert(save_synchronizer)
	assert(save_synchronizer.save_container == save_container)


func _prepare_save_dir() -> void:
	if not OS.has_feature("editor"):
		save_dir = save_dir.replace("res://", "user://")
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)

# ------------------------
# Public API
# ------------------------


func save_state() -> Error:
	var err: Error = ResourceSaver.save(save_container, save_path)
	assert(err == OK,
		"Failed to save `%s`. Error: %s" % [save_path, error_string(err)])
	return err


func load_state() -> Error:
	if not ResourceLoader.exists(save_path):
		#push_warning("No file found at path: %s" % save_path)
		return ERR_FILE_NOT_FOUND
	
	var saved_container := ResourceLoader.load(
		save_path, 
		"SaveContainer", 
		ResourceLoader.CACHE_MODE_REPLACE)
	
	if saved_container == null:
		push_error("Save located at `%s` is invalid." % save_path)
		return ERR_CANT_OPEN

	save_container = saved_container
	push_to_scene()
	
	return OK


func deserialize_scene(bytes: PackedByteArray) -> void:
	save_container.deserialize(bytes)
	push_to_scene()
	
func serialize_scene() -> PackedByteArray:
	pull_from_scene()
	return save_container.serialize()


func push_to_scene() -> Error:
	var push_err: Error = save_synchronizer.push_to_scene()
	match push_err:
		ERR_UNCONFIGURED:
			push_error("Removing unconfigured save at `%s`." % save_path)
			DirAccess.remove_absolute(save_path)
			return push_err
		_:
			return push_err


func pull_from_scene() -> void:
	save_synchronizer.pull_from_scene()


func push_to(peer_id: int) -> void:
	save_synchronizer.push_to(peer_id)


func on_state_changed() -> void:
	save_state()
	state_changed.emit()


func _on_instantiate() -> void:
	save_synchronizer.setup()
	assert(save_synchronizer._initialized)
