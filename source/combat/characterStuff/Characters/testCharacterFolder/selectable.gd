@tool
extends CanvasItem

@export_range(0.0, 1.0) var opacity: float = 0.75:
	set(value):
		opacity = value
		if owner_ci.modulate.a != 1.0:
			owner_ci.modulate.a = opacity

var owner_ci: CanvasItem:
	get:
		return owner as CanvasItem

func select() -> void:
	owner_ci.modulate.a = 1.0

func deselect() -> void:
	owner_ci.modulate.a = opacity

func _ready() -> void:
	deselect()


func _on_focus_entered() -> void:
	select()


func _on_focus_exited() -> void:
	deselect()
