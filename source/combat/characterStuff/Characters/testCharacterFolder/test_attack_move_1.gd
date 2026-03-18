extends charAttack
 

var dmgAdder = 0

#var testParent = get_parent()

#@onready var test2 = get_parent().testTransfer
#^^^^ tf?????

func _init() -> void:
	pass
func _ready() -> void: #doesnt load the parent
	baseAttackDmg = 50
	pass

func attack() -> int:
	return baseAttackDmg


func attackScale(damageScale: int) -> int:
	return baseAttackDmg + damageScale


func _on_test_character_transfer_stats(health: int, dmg: int, will: int, defense: int, blockingDefense: int, courage: int) -> void:
	dmgAdder = dmg 
	pass # Replace with function body.
