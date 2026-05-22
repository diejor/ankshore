class_name Character extends Node2D

## Represents a participant in a combat encounter on the battlefield.

signal action_finished(action: CombatAction)
signal health_depleted
signal will_depleted
signal courage_depleted
signal transferStats(stats: CharacterStats)

@export var stats: CharacterStats = CharacterStats.new()
@export var move_list: Array[CombatAction] = []

@onready var action_label: Label = %ActionLabel

## Parent team manager caching property.
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


func _ready() -> void:
	_update_facing_direction()
	transferStats.emit(stats)
	print("Character node '%s' is ready" % name)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next"):
		var other_team := team_manager.get_other_team()
		if other_team and other_team.slots.size() > 0:
			other_team.slots[0].grab_focus.call_deferred()


## Returns a list of active physical attacks in the move list.
func get_attacks() -> Array:
	var filter_attacks := func(action: CombatAction) -> bool:
		return action is AttackAction
	return move_list.filter(filter_attacks)


## Forces a UI update by emitting character stats.
func recalculate_moves() -> void:
	transferStats.emit(stats)


## Deals [param raw_damage] to character stats after checking blocks.
func take_dmg(raw_damage: int, blocked: bool) -> void:
	stats.change_health(-raw_damage)
	if stats.health <= 0:
		health_depleted.emit()


## Initiates the character action decision phase.
func start_action() -> CombatAction:
	action_label.text = "Choosing action..."
	
	# Simulate character action choice delay
	await get_tree().create_timer(1.0).timeout
	
	action_label.text = "Action executed!"
	var dummy_action := CombatAction.new()
	action_finished.emit(dummy_action)
	return dummy_action


## Modulates character modulate scaling to reflect team direction.
func _update_facing_direction() -> void:
	var tm := team_manager
	if tm and tm.team == TeamManager.Team.Enemy:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	else:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
