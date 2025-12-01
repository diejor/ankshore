class_name SaveComponent
extends Node

signal state_changed
signal spawn

@export_dir var save_dir: String
@export var save_extension: String = ".tdict"

@export var save_container: SaveContainer

@onready var save_synchronizer: SaveSynchronizer:
	get:
		return %SaveSynchronizer
@onready var base_sync: MultiplayerSynchronizer:
	get:
		return %MultiplayerSynchronizer

@onready var save_path: String:
	get:
		_prepare_save_dir()
		assert(save_extension.begins_with("."), "Save extension should begin with a dot.")
		save_path = save_dir.path_join(owner.name + save_extension)
		assert(save_path.is_absolute_path(), "Invalid save to a not valid file path. " + save_path)
		return save_path

func _enter_tree() -> void:
	save_synchronizer.setup_from(base_sync, save_container)

func _ready() -> void:
	assert(save_container, "SaveComponent requires a SaveContainer.")
	assert(save_synchronizer, "SaveComponent needs a SaveSynchronizer reference.")
	assert(base_sync, "SaveComponent expects a unique node %MultiplayerSynchronizer in the scene.")

	# Make sure both point to the same container
	assert(save_synchronizer.save_container == save_container,
		"SaveComponent and SaveSynchronizer should share the same SaveContainer instance.")

func _prepare_save_dir() -> void:
	if not Engine.is_editor_hint():
		if save_dir.begins_with("res://"):
			save_dir = save_dir.replace("res://", "user://")
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)

# ------------------------
# Public API
# ------------------------

func load_state() -> Error:
	var load_error: Error = save_container.load_state(save_path)
	if load_error == Error.OK:
		var push_with_signal := func() -> void:
			save_synchronizer.push_to_scene()
			spawn.emit()
		push_with_signal.call_deferred()
	return load_error

func save_state() -> Error:
	var save_error: Error = save_container.save_state(save_path)
	assert(save_error == OK, "Something went wrong while saving: %s" % error_string(save_error))
	return save_error

func force_state_sync() -> void:
	save_synchronizer.force_state_sync()

func on_state_changed() -> void:
	save_state()
	state_changed.emit()
