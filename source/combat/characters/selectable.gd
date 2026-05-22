@tool
extends CanvasItem

## Focus visualizer script that modulates parent opacity when focused.
##
## Standardizes alpha transparency feedback during focus events.

## Modulation opacity applied to unfocused canvas items.
@export_range(0.0, 1.0) var opacity: float = 0.75:
	set(value):
		opacity = value
		if owner_ci and owner_ci.modulate.a != 1.0:
			owner_ci.modulate.a = opacity

## Parent CanvasItem node reference.
var owner_ci: CanvasItem:
	get:
		return owner as CanvasItem


func _ready() -> void:
	deselect()


## Modulates modulation alpha back to full visibility on selection focus.
func select() -> void:
	if owner_ci:
		owner_ci.modulate.a = 1.0


## Diminshes modulation alpha back to the default [member opacity] when blurred.
func deselect() -> void:
	if owner_ci:
		owner_ci.modulate.a = opacity


# Triggered when selection slot focus is entered.
func _on_focus_entered() -> void:
	select()


# Triggered when selection slot focus is exited.
func _on_focus_exited() -> void:
	deselect()
