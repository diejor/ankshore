extends Node

signal slot_saved(slot_name: String)
signal slot_loaded(slot_name: String, success: bool)

const SAVE_VERSION := 1
const KEY_COMPONENTS := "components"

const FileSaveBackend := preload("res://Source/Myoso/Save/file_save_backend.gd")

@export var default_slot := "local_player"

var backend: SaveBackend

var _components: Array = []
var _cached_slot_data: Dictionary = {}
var _active_slot := ""

func _ready() -> void:
	if backend == null:
		backend = FileSaveBackend.new()

func register_component(component: SaveComponent) -> void:
	if component == null:
		return
	if _components.has(component):
		return
	_components.append(component)
	_apply_cached_state(component)

func unregister_component(component: SaveComponent) -> void:
	if component == null:
		return
	_components.erase(component)

func save_slot(slot_name: String = default_slot) -> Error:
	if backend == null:
		backend = FileSaveBackend.new()
	var snapshot := _build_snapshot()
	var result := backend.save(slot_name, snapshot)
	if result == OK:
		_active_slot = slot_name
		var cache = snapshot.get(KEY_COMPONENTS, {})
		_cached_slot_data = cache if typeof(cache) == TYPE_DICTIONARY else {}
		slot_saved.emit(slot_name)
	return result

func load_slot(slot_name: String = default_slot) -> bool:
	if backend == null:
		backend = FileSaveBackend.new()
	var data := backend.load(slot_name)
	var success := not data.is_empty()
	var components = data.get(KEY_COMPONENTS, {})
	if typeof(components) != TYPE_DICTIONARY:
		components = {}
	_cached_slot_data = components
	_active_slot = slot_name
	_apply_cached_state_to_all()
	slot_loaded.emit(slot_name, success)
	return success

func get_cached_component_state(id: StringName) -> Dictionary:
	return _cached_slot_data.get(str(id), {})

func get_active_slot() -> String:
	return _active_slot

func _build_snapshot() -> Dictionary:
	var payload := {}
	for component in _components:
		if not is_instance_valid(component):
			continue
		var node = component.owner
		if node == null or not node.is_inside_tree():
			continue
		if not node.is_in_group("persistent"):
			continue
		var id := str(component.get_save_id())
		if id.is_empty():
			continue
		var serialized = component.serialize()
		if serialized.is_empty():
			continue
		payload[id] = serialized
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		KEY_COMPONENTS: payload
	}

func _apply_cached_state_to_all() -> void:
	for component in _components:
		_apply_cached_state(component)

func _apply_cached_state(component: SaveComponent) -> void:
	if component == null:
		return
	var id := str(component.get_save_id())
	if id.is_empty():
		return
	var entry = _cached_slot_data.get(id, null)
	if typeof(entry) == TYPE_DICTIONARY:
		component.deserialize(entry)
