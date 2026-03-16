extends Node
class_name charAction
@export var target: Array[testCharacter]

func itemUse() -> void:
	
	pass

func _to_string() -> String:
	return "charAction"

func attack() -> int:
	
	return 5

func execute() -> void:
	for player in target:
		player.applyAction(self)
