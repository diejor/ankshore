class_name SaveSynchronizer
extends MultiplayerSynchronizer

signal state_changed

@export var base_sync: MultiplayerSynchronizer:
	get:
		return %MultiplayerSynchronizer

@onready var save_container: SaveContainer:
	get:
		@warning_ignore("unsafe_property_access")
		return %SaveComponent.save_container

var _property_paths: Dictionary[StringName, NodePath] = {}

var _initialized: bool = false

var _state_changed: bool = false

func _ready() -> void:
	if not _initialized:
		setup()
	assert(_initialized, "Scynchronizer not initialized.")
	
func _on_instantiate() -> void:
	setup()
	assert(_initialized, "Scynchronizer not initialized.")

func setup() -> void:
	if _initialized:
		push_warning("Initializing once again.")
		return
	_initialized = true
	
	assert(save_container)
	assert(base_sync)
	assert(base_sync.replication_config)
	assert(save_container.resource_local_to_scene, 
		"`%s` is not local to scene." % save_container)

	_virtualize_replication_config(base_sync.replication_config)
	notify_property_list_changed()
	
	var only_server: Callable = func (peer_id: int) -> bool: return peer_id == 1
	add_visibility_filter(only_server)
	update_visibility()

# ------------------------
# Virtualization helpers
# ------------------------

func _virtualize_replication_config(source_config: SceneReplicationConfig) -> void:
	var new_config := SceneReplicationConfig.new()
	_property_paths.clear()

	for real_path: NodePath in source_config.get_properties():
		var mode := source_config.property_get_replication_mode(real_path)
		var spawn := source_config.property_get_spawn(real_path)
		var sync_flag := source_config.property_get_sync(real_path)
		var watch := source_config.property_get_watch(real_path)

		var node_res: Array = owner.get_node_and_resource(real_path)
		assert(node_res[0],
			"Trying to synchronize '%s' which is not a valid property path. Check source_config." % real_path)

		var node: Node = node_res[0]
		var prop_path: NodePath = node_res[2]

		var is_root := node == owner
		var node_label := "" if is_root else String(node.name)

		var leaf: String
		if prop_path.get_subname_count() > 0:
			leaf = prop_path.get_subname(prop_path.get_subname_count() - 1)
		else:
			leaf = String(prop_path).trim_prefix(":")

		var virtual_name: String
		if is_root:
			virtual_name = leaf                      # "position"
		else:
			virtual_name = node_label + "/" + leaf   # "TPComponent/current_scene_name"

		var vname_sn := StringName(virtual_name)
		assert(not _property_paths.has(vname_sn),
			"Virtual property name '%s' from '%s' is duplicated. 
			Use unique node names or adjust mapping." % [virtual_name, String(real_path)])

		_property_paths[vname_sn] = real_path

		var virtual_path := NodePath(":" + virtual_name)

		new_config.add_property(virtual_path)
		new_config.property_set_replication_mode(virtual_path, mode)
		new_config.property_set_spawn(virtual_path, spawn)
		new_config.property_set_sync(virtual_path, sync_flag)
		new_config.property_set_watch(virtual_path, watch)

		if not save_container.has_value(vname_sn):
			var value: Variant = node.get_indexed(prop_path)
			save_container.set_value(vname_sn, value)

	root_path = NodePath(".")
	replication_config = new_config

# ------------------------
# Virtual property interface
# ------------------------

func _get_tracked_property_names() -> Array[StringName]:
	return _property_paths.keys()

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	for property_name: StringName in _get_tracked_property_names():
		var value: Variant = save_container.get_value(property_name, null)
		properties.append({
			"name": property_name,
			"type": typeof(value),
		})
	return properties

func has_state_property(property: StringName) -> bool:
	return _property_paths.has(property)

func _get_scene_value(property_name: StringName) -> Variant:
	var real_path: NodePath = _property_paths[property_name]
	var node_res := owner.get_node_and_resource(real_path)
	assert(node_res[0], "Invalid real property path for get_scene_value: %s" % String(real_path))
	var node: Node = node_res[0]
	var prop_path: NodePath = node_res[2]
	return node.get_indexed(prop_path)

func _set_scene_value(property_name: StringName, value: Variant) -> void:
	var real_path: NodePath = _property_paths[property_name]
	var node_res := owner.get_node_and_resource(real_path)
	assert(node_res[0], "Invalid real property path for set_scene_value: %s" % String(real_path))
	var node: Node = node_res[0]
	var prop_path: NodePath = node_res[2]
	node.set_indexed(prop_path, value)

func _get(property: StringName) -> Variant:
	if has_state_property(property):
		return _get_scene_value(property)
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	if has_state_property(property):
		save_container.set_value(property, value)
		
		# Collect changes into a single frame
		_state_changed = true
		save_once.call_deferred()
		
		return true
	
	return false

func save_once() -> void:
	if _state_changed:
		state_changed.emit()
		_state_changed = false

# ------------------------
# Scene <-> SaveContainer sync
# ------------------------

func pull_from_scene() -> void:
	assert(_initialized, "Scynchronizer not initialized.")
	for property_name: StringName in _get_tracked_property_names():
		var value: Variant = _get_scene_value(property_name)
		save_container.set_value(property_name, value)
	state_changed.emit()

func push_to_scene() -> Error:
	assert(_initialized, "Scynchronizer not initialized.")
	assert(save_container)

	for property_name in save_container:
		var pname := StringName(property_name)
		if not has_state_property(pname):
			push_error(
				"Trying to push state with property 
				'%s' that is not tracked by the SaveSynchronizer." % property_name)
			return Error.ERR_UNCONFIGURED
		
		var value: Variant = save_container.get_value(pname)
		if value == null:
			push_error(
				"Trying to push state but the save doesn't have property 
				'%s' that is tracked by the SaveSynchronizer." % property_name)
			return Error.ERR_UNCONFIGURED

		_set_scene_value(pname, value)
	
	return Error.OK

func force_state_sync() -> void:
	pull_from_scene()
	_force_state_sync.rpc_id(1, save_container.serialize())

@rpc("any_peer", "call_remote")
func _force_state_sync(state_bytes: PackedByteArray) -> void:
	save_container.deserialize(state_bytes)
	push_to_scene()
	state_changed.emit()
