extends Node2D

func _ready() -> void:
	visible = false


func on_connected_to_server() -> void:
	visible = true


func _on_myoso_spawn() -> void:
	set_deferred("visible", true)
