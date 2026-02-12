extends Node

@export var baseMove: Resource = preload("res://source/combat/characterStuff/anatomy/charAttack.gd")
#@onready var testCharBaseDmg: testCharacter = $".." #I UNDERS
#@export var testCharBase: PackedScene = preload("res://source/combat/characterStuff/Characters/testCharacterFolder/TestCharacter.tscn")
#@onready var test_character: testCharacter = $".."
#var lol = get_parent().getBaseCharDmg()


var testParent = get_parent()

@onready var test2 = get_parent().testTransfer
func _init() -> void:
	baseMove.recalculateStats(test2)
	print(baseMove.attack())
	#fuck you
func _ready() -> void:
	print("hello")
	print(baseMove.attack())
	if testParent:
		print("hi")
		print(testParent.testTransfer)
	print()


func _on_test_character_transfer_stats(dmg: int) -> void:
	print("this better work")
	print(dmg)
	pass # Replace with function body.
