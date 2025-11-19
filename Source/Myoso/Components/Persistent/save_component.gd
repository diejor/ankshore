class_name SaveComponent
extends Node

@export var save_id: StringName
@export var save: DataResource

@onready var offline_sync: OfflineSynchronizer = %OfflineSynchronizer

var property_map: Dictionary[StringName, NodePath]

func _ready() -> void:
	save.changed.connect(on_save_changed)
	
	for property_path: NodePath in offline_sync.get_properties_path():
		var property_name: StringName = offline_sync.get_property_name(property_path)
		property_map[property_name] = property_path
			

func on_spawn(_save: DataResource) -> void:
	for property_name: StringName in property_map.keys():
		
		var saved_property: Variant = _save.get(property_name)
		assert(saved_property, "`OfflineSynchronizer` is trying to 
		synchronize `%s` which is a a property that the given `save` doesn't 
		know about." % property_name)
		
		var property_path: NodePath = property_map[property_name]
		offline_sync.set_property(property_path, saved_property)

func on_save_changed() -> void:
	print("Save changed!")
