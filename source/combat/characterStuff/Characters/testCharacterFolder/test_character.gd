class_name testCharacter extends Node2D




@export var stats: charStats = charStats.new()

#fuck
@export var moveList: Array[charAction] = []
#have set of moves instatiated here
#moveList.push_front(test_attack_move_1) #doesnt work

@warning_ignore("unused_signal")
signal health_depleted
@warning_ignore("unused_signal")
signal will_depleted
@warning_ignore("unused_signal")
signal courage_depleted
signal transferStats(stats: charStats)
#transferStats.emit(stats.health, stats.damageStat, stats.will, stats.defense, stats.blockingDefense, stats.courage)
#signal transferStats(dmg: int)
#health
#damageStat
#will
#defense 
#blockingDefense
#courage

func get_attacks() -> Array:
	var filter_attacks := func(action: charAction) -> bool:
		return action is charAttack
	
	return moveList.filter(filter_attacks)

### gameplay Stuff
func recalculateMoves() -> void:
	transferStats.emit(stats)
	
func takeDmg(rawDamage: int, blocked: bool) -> void:
	stats.damageTaken(rawDamage, blocked)
	
	pass
	
func blockingChance() -> void: #???
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
