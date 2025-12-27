extends Area2D

@export var dialog_key = ""
var area_active = false

func _input(event):
	if area_active and event.is_action_pressed("ui_accept"):
		SignalBusDialogue.emit_signal("display_dialog", dialog_key)


func _on_area_entered(area: Area2D) -> void:
	print("Myoso entered command grab range")
	area_active = true


func _on_area_exited(area: Area2D) -> void:
	print("Myoso exited command grab range")
	area_active = false
