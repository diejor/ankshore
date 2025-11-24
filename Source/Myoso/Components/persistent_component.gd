## Preserve the parent node even when the SceneTree changes of
## scene, works closely with the autoload `SceneManager` to accomplish that.
class_name PersistentComponent
extends Node

@onready var autoload_signals: AutoloadSignals = %AutoloadSignals

@export var is_active: IsActive

func _ready() -> void:
	var offline_name := owner.name
	var offline_node: Node = owner.get_node_or_null("%"+offline_name)
	if not is_active.active:
		is_active.active = true
		await autoload_signals.scene_changed
		Client.connected_to_server.emit()
		return
	
	if offline_node != null:
		offline_node.queue_free()
