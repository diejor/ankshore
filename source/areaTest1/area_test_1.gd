extends Node2D

func _ready() -> void:
	MyosoManager.get_child(0).reparent($".")
	pass
