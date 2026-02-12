class_name testCharacter extends Node2D


@export var stats: Resource = preload("res://source/combat/characterStuff/anatomy/charStats.gd")

var baseCharDmg = stats.getDamageStat()

var testTransfer = 42


signal health_depleted
signal will_depleted
signal courage_depleted

signal transferStats(dmg: int)


func getBaseCharDmg() -> int:
	return baseCharDmg
	
	
func _ready() -> void:
	transferStats.emit(baseCharDmg)
	print("sup")
	print(stats.getDamageStat())
func _init() -> void:
	
		
	pass


#main brain of testCharacter
