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

## The parent [TeamManager] resolved dynamically by traversing ancestors.
var team_manager: TeamManager:
	get:
		if _team_manager_cache:
			return _team_manager_cache
		var p := get_parent()
		while p and not p is TeamManager:
			p = p.get_parent()
		_team_manager_cache = p as TeamManager
		return _team_manager_cache

var _team_manager_cache: TeamManager = null

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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next"):
		var other_team: TeamManager = team_manager.get_other_team()
		other_team.slots[0].grab_focus.call_deferred()
		

func _ready() -> void:
	_update_facing_direction()
	transferStats.emit(stats)
	print("testCharacter node is ready")


# Updates the character's horizontal flip based on its team assignment.
func _update_facing_direction() -> void:
	var tm := team_manager
	if tm and tm.team == TeamManager.Team.Enemy:
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	else:
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
	
###
func _init() -> void:
	
		
	pass

###testing Stuff
#func getBaseCharDmg() -> int:
	#return baseCharDmg
	#
