extends Node

@export var baseMove: Resource = preload("res://source/combat/characterStuff/anatomy/charAttack.gd")

var baseMoveDmg = 10
var dmgAdder = 0

var testParent = get_parent()

@onready var test2 = get_parent().testTransfer


func _init() -> void:
	pass
func _ready() -> void: #doesnt load the parent
	pass

func attack() -> int:
	return baseMoveDmg + dmgAdder



func _on_test_character_transfer_stats(health: int, dmg: int, will: int, defense: int, blockingDefense: int, courage: int) -> void:
	dmgAdder = dmg 
	pass # Replace with function body.
