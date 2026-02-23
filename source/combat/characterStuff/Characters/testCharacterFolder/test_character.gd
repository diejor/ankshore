class_name testCharacter extends Node2D




@export var stats: charStats = charStats.new()

#fuck
var moveList: Array[charAction] = []
#moveList.push_front(test_attack_move_1) #doesnt work

signal health_depleted
signal will_depleted
signal courage_depleted
signal transferStats(health: int, dmg: int, will: int, defense: int, blockingDefense: int, courage: int)
#transferStats.emit(stats.health, stats.damageStat, stats.will, stats.defense, stats.blockingDefense, stats.courage)
#signal transferStats(dmg: int)
#health
#damageStat
#will
#defense 
#blockingDefense
#courage



### gameplay Stuff
func recalculateMoves() -> void:
	transferStats.emit(stats.health, stats.damageStat, stats.will, stats.defense, stats.blockingDefense, stats.courage)
	
func takeDmg(rawDamage: int, blocked: bool) -> void:
	stats.damageTaken(rawDamage, blocked)
	
	pass
	
###other
func _ready() -> void:
	transferStats.emit(stats.health, stats.damageStat, stats.will, stats.defense, stats.blockingDefense, stats.courage)
	print("testCharacter node is ready")
	
###
func _init() -> void:
	
		
	pass

###testing Stuff
#func getBaseCharDmg() -> int:
	#return baseCharDmg
	#
