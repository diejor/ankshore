class_name Character extends Node2D

## Represents a participant in a combat encounter on the battlefield.

@warning_ignore("unused_signal")
signal action_finished(action: CombatAction)
signal health_depleted
@warning_ignore("unused_signal")
signal will_depleted
@warning_ignore("unused_signal")
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


## Returns all [CombatAction] nodes attached as direct children plus
## any actions in [member move_list], without duplicates. Used by
## [MoveSelectionStep] to populate the move list UI.
func available_moves() -> Array[CombatAction]:
	var result: Array[CombatAction] = []
	for child in get_children():
		if child is CombatAction:
			result.append(child)
	for action in move_list:
		if action and not result.has(action):
			result.append(action)
	return result


## Returns active physical attacks among [method available_moves].
func get_attacks() -> Array[CombatAction]:
	var attacks: Array[CombatAction] = []
	for action in available_moves():
		if action is AttackAction:
			attacks.append(action)
	return attacks


## True when [member stats] are present and [member CharacterStats.health]
## is positive.
func is_alive() -> bool:
	return stats != null and stats.health > 0


## Forces a UI update by emitting character stats.
func recalculate_moves() -> void:
	transferStats.emit(stats)


## Deals [param raw_damage] to character stats after checking blocks.
@warning_ignore("unused_parameter")
func take_dmg(raw_damage: int, blocked: bool) -> void:
	stats.change_health(-raw_damage)
	if stats.health <= 0:
		health_depleted.emit()


## Modulates character modulate scaling to reflect team direction.
func _update_facing_direction() -> void:
	var tm := team_manager
	if tm and tm.team == TeamManager.Team.Enemy:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	else:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
