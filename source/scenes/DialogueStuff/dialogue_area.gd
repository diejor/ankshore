extends Area2D

@export var dialog_key: String = ""
var area_active: bool = false

func _input(event: InputEvent) -> void:
	if area_active and event.is_action_pressed("ui_accept"):
		SignalBusDialogue.emit_signal("display_dialog", dialog_key)


func _on_body_entered(body: Node2D) -> void:
	if body.is_multiplayer_authority():
		print("Myoso entered command grab range")
		area_active = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_multiplayer_authority():
		print("Myoso exited command grab range")
		area_active = false
