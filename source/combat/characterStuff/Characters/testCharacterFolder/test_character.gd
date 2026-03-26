class_name testCharacter extends Node2D


@export var stats: charStats = charStats.new()


@export var moveList: Array[charAction] = []
#have set of moves instatiated here

signal action_finished(action: charAction)

@warning_ignore("unused_signal")
signal health_depleted
@warning_ignore("unused_signal")
signal will_depleted
@warning_ignore("unused_signal")
signal courage_depleted
signal transferStats(stats: charStats)
#transferStats.emit(stats.health, stats.damageStat, stats.will, stats.defense, stats.blockingDefense, stats.courage)

@onready var action_label: Label = %ActionLabel

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


func start_action() -> charAction:
	action_label.text = "Creating Action... "
	# simulate player making inputs
	await get_tree().create_timer(5.0).timeout
	action_label.text = "Action finished!"
	# player finished
	action_finished.emit(charAction.new())

	return charAction.new()

func applyAction(action: charAction) -> void:
	match action:
		charAttack:
			stats.damageTaken(action.attackScale(stats.damageStat), true) #needs to figure out blocking later
			pass
		charSupport:
			pass
		charItemUse:
			pass


###other
func _ready() -> void:
	var team_manager: TeamManager = owner as TeamManager
	if team_manager.team == TeamManager.Team.Enemy:
		scale.x *= -1.0
	
	transferStats.emit(stats.health, stats.damageStat, stats.will, stats.defense, stats.blockingDefense, stats.courage)
	print("testCharacter node is ready")
	
###
func _init() -> void:
	
		
	pass

###testing Stuff
#func getBaseCharDmg() -> int:
	#return baseCharDmg
	#
