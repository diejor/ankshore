class_name SaveComponent
extends MultiplayerSynchronizer

signal state_changed

@export_dir var save_dir: String
@onready var save_file_name: String = owner.name
@onready var save_slot: String = save_dir.path_join(save_file_name)

@export var state_container: DataResource


var property_to_path: Dictionary[StringName, NodePath]
var save_config: SceneReplicationConfig
var source_config: SceneReplicationConfig
var real_root_path: NodePath


func _ready() -> void:
	assert(state_container, "Please specify the `DataResource` that will keep track of the save.")
	
	assert(state_container.resource_local_to_scene, 
		"Make the exported `DataResource` container `local_to_scene = true` through the 
		inspector, otherwise saves will be shared.")

	assert(replication_config, "SaveComponent requires an initial `replication_config` with real properties.")
	source_config = replication_config
	real_root_path = root_path
	
	if OS.has_feature("standalone"):
		push_warning("Replacing `res://` with `user://` because running as exported.")
		save_dir.replace("res://", "user://")

	_sync_from_source_config()
	notify_property_list_changed()
	_build_save_replication_config()
	_configure_visibility()
	
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)

func _sync_from_source_config() -> void:
	property_to_path.clear()

	assert(source_config, "SaveComponent requires `source_config`.")
	assert(real_root_path != NodePath(""), "SaveComponent `real_root_path` must be set before `_ready`.")
	var root_node: Node = get_node(real_root_path)

	var paths: Array = source_config.get_properties()
	for path: NodePath in paths:
		var node_res: Array = root_node.get_node_and_resource(path)
		assert(node_res[0],
			"Trying to synchronize '" + str(path) + "' which is not a valid property path. Check `replication_config`.")

		var prop_path: NodePath = node_res[2]
		if prop_path.get_subname_count() == 0:
			continue

		var property_name: StringName = _make_virtual_property_name(root_node, path)

		assert(property_name != StringName(""),
			"Replicated property from '" + str(path) + "' generated empty virtual name.")

		assert(not property_to_path.has(property_name),
			"Virtual property name '" + str(property_name) + "' from path '" + str(path) + "' is duplicated. Check `replication_config`.")

		property_to_path[property_name] = path

		if not state_container.has_value(property_name):
			state_container.set_value(property_name, _get_path_value(path))


func _make_virtual_property_name(root_node: Node, property_path: NodePath) -> StringName:
	var node_res: Array = root_node.get_node_and_resource(property_path)
	assert(node_res[0],
		"Trying to synchronize '" + str(property_path) + "' which is not a valid property path. Check `replication_config`.")

	var node: Node = node_res[0]
	var prop_path: NodePath = node_res[2]

	var leaf: String
	if prop_path.get_subname_count() > 0:
		leaf = prop_path.get_subname(prop_path.get_subname_count() - 1)
	else:
		leaf = str(prop_path)

	return StringName(str(node.name, "/", leaf))


func _set_path_value(property_path: NodePath, value: Variant) -> void:
	var root_node: Node = get_node(real_root_path)

	var node_res: Array = root_node.get_node_and_resource(property_path)
	assert(node_res[0],
		"Trying to write '" + str(property_path) + "' which is not a valid property path. Check `replication_config`.")

	var node: Node = node_res[0]
	var prop_path: NodePath = node_res[2]
	node.set_indexed(prop_path, value)


func _get_path_value(property_path: NodePath) -> Variant:
	var root_node: Node = get_node(real_root_path)

	var node_res: Array = root_node.get_node_and_resource(property_path)
	assert(node_res[0],
		"Trying to read '" + str(property_path) + "' which is not a valid property path. Check `replication_config`.")

	var node: Node = node_res[0]
	var prop_path: NodePath = node_res[2]
	return node.get_indexed(prop_path)


func _build_save_replication_config() -> void:
	assert(source_config, "SaveComponent expects `source_config` to be set before building save config.")

	if not save_config:
		save_config = SceneReplicationConfig.new()

	var existing: Array = save_config.get_properties()
	for p: NodePath in existing:
		save_config.remove_property(p)

	for virtual_name: StringName in property_to_path.keys():
		var real_path: NodePath = property_to_path[virtual_name]
		var virtual_path := NodePath(":" + str(virtual_name))

		if not save_config.has_property(virtual_path):
			save_config.add_property(virtual_path)

		var mode := source_config.property_get_replication_mode(real_path)
		var spawn := source_config.property_get_spawn(real_path)
		var sync_flag := source_config.property_get_sync(real_path)
		var watch := source_config.property_get_watch(real_path)

		save_config.property_set_replication_mode(virtual_path, mode)
		save_config.property_set_spawn(virtual_path, spawn)
		save_config.property_set_sync(virtual_path, sync_flag)
		save_config.property_set_watch(virtual_path, watch)

	root_path = NodePath(".")
	replication_config = save_config


func _get_property_list() -> Array[Dictionary]:
	assert(not property_to_path.is_empty(),
		"SaveComponent `property_to_path` is empty. Did `_sync_from_source_config()` run?")

	var properties: Array[Dictionary] = []

	for property_name: StringName in property_to_path.keys():
		var value: Variant = state_container.get_value(property_name, null)
		var type_id := typeof(value)

		properties.append({
			"name": property_name,
			"type": type_id,
		})

	return properties


func _get(property: StringName) -> Variant:
	if not property_to_path.has(property):
		return null

	var path: NodePath = property_to_path[property]
	var value: Variant = _get_path_value(path)
	return value


func _set(property: StringName, value: Variant) -> bool:
	if not property_to_path.has(property):
		return false

	state_container.set_value(property, value)
	state_changed.emit()
	return true


func has_state_property(property: StringName) -> bool:
	return property_to_path.has(property)


func refresh_property_list_from_source() -> void:
	_sync_from_source_config()
	notify_property_list_changed()
	_build_save_replication_config()


func _configure_visibility() -> void:
	add_visibility_filter(only_server_filter)
	update_visibility()


func only_server_filter(peer_id: int) -> bool:
	return peer_id == 1


func apply_save() -> void:
	assert(state_container, "SaveComponent.apply_save() requires a valid DataResource.")

	for property_name in state_container:
		assert(has_state_property(property_name), 
			"Trying to `apply_save` with property `%s` that is not tracked by the 
			`SaveComponent`." % property_name)

		var path: NodePath = property_to_path[property_name]
		var value: Variant = state_container.get_value(property_name)
		assert(value != null, "Trying to `apply_save` but the save doesn't have property `%s`
			that is tracked by the `SaveComponent`." % property_name)
		_set_path_value(path, value)


func on_state_changed() -> void:
	var save_error: Error = state_container.save_state(save_slot)
	assert(save_error == OK, 
			"Something went wrong while saving: %s" % error_string(save_error))
