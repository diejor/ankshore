extends Node

func _ready() -> void:
	if has_node("../%"+get_parent().name):
		var node = get_node("../%"+get_parent().name)
		if not GameInstance.is_online():
			if not GameInstance.has_node("Myoso"):
				node.reparent.call_deferred(GameInstance)
			else:
				node.queue_free()
		else:
			node.queue_free()
