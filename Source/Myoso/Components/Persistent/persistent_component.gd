## Preserve the parent node even when the SceneTree changes of
## scene, works closely with the autoload `SceneManager` to accomplish that.
class_name PersistentComponent
extends Node

func _ready() -> void:
	var offline_name := owner.name
	var offline_node := owner.get_node_or_null("%"+offline_name)
	if offline_node == null and not GameInstance.is_online():
		push_warning("The player doesn't have a `Unique Name`. 
		Right click the player node and enable `Access as Unique Name`")
		return
	
	if offline_node and GameInstance.is_online():
		# Offline players are removed from the level.
		offline_node.queue_free()
		return
		
	if not GameInstance.is_online():
		if GameInstance.scene_manager.has_node(NodePath(offline_name)):
			# GameInstance has a player already, remove offline
			offline_node.queue_free()
		else:
			# GameInstance doesn't have a permanent player yet, add it
			offline_node.reparent.call_deferred(GameInstance.scene_manager)
