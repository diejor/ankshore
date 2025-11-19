class_name SaveComponent
extends Node

@export var _save_id: StringName
@export var _save: DataResource

@onready var offline_sync: OfflineSynchronizer = %OfflineSynchronizer

var property_map: Dictionary[StringName, NodePath]

func _ready() -> void:
	_save.changed.connect(on_save_changed)
	
	for property_path: NodePath in offline_sync.get_properties_path():
		var property_name: StringName = offline_sync.get_property_name(property_path)
		property_map[property_name] = property_path
	
	if OS.is_debug_build():
		for data_property: StringName in _save.properties:
			assert(data_property in property_map,
	            "All properties in `DataResource` should be tracked by the 
				replication configuration of `OfflineSynchronizer`")

func _apply_save() -> void:
	for property_name: StringName in _save.properties:
		var property_path: NodePath = property_map[property_name]
		offline_sync.set_property(property_path, _save.get(property_name))

func on_save_changed() -> void:
	print("Save changed!")
