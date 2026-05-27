class_name Character extends Node2D

## Represents a participant in a combat encounter on the battlefield.

enum DefenseKind { BLOCK, PARRY }

@warning_ignore("unused_signal")
signal action_finished(action: CombatAction)
signal health_depleted
@warning_ignore("unused_signal")
signal will_depleted
@warning_ignore("unused_signal")
signal courage_depleted
signal defense_window_opened(
	kind: DefenseKind,
	beat: AttackBeat,
	window_sec: float
)
signal defense_window_closed(result: DefenseInput)
@warning_ignore("unused_signal")
signal beat_telegraphed(beat: AttackBeat)
@warning_ignore("unused_signal")
signal beat_resolved(beat: AttackBeat, blocked: bool, damage: int)
@warning_ignore("unused_signal")
signal ender_resolved(ender: int, hit: bool, damage: int)

@export var stats: CharacterStats = CharacterStats.new()
@export var move_list: Array[CombatAction] = []

## Move selected for this character's next resolution step.
var pending_move: CombatAction = null

## Targets selected for [member pending_move].
var pending_targets: Array[Character] = []

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


## Returns all [CombatAction] nodes attached as direct children plus
## any actions in [member move_list], without duplicates. Used by
## [MoveListUI] to render the move-pick view.
func available_moves() -> Array[CombatAction]:
	var result: Array[CombatAction] = []
	for child in get_children():
		if child is CombatAction:
			result.append(child)
	for action in move_list:
		if action and not result.has(action):
			result.append(action)
	return result


## True when [member stats] are present and [member CharacterStats.health]
## is positive.
func is_alive() -> bool:
	return stats != null and stats.health > 0


## Stores the move and targets this character will execute this turn.
func commit_move(move: CombatAction, targets: Array[Character]) -> void:
	pending_move = move
	pending_targets = targets.duplicate()


## Clears the move and targets committed for this turn.
func clear_pending_move() -> void:
	pending_move = null
	pending_targets = []


## Executes [member pending_move], then clears the pending turn data.
func execute_turn(ctx: PhaseContext) -> void:
	if pending_move == null:
		return
	await pending_move.execute_async(self, pending_targets, ctx)
	clear_pending_move()


## Opens a defense window and awaits the defending controller's result.
func request_defense(
	kind: DefenseKind,
	beat: AttackBeat,
	window_sec: float
) -> DefenseInput:
	defense_window_opened.emit(kind, beat, window_sec)
	var result: DefenseInput = await defense_window_closed
	if result == null:
		return DefenseInput.none()
	return result


## Reports the defender's reaction back to the resolver.
func complete_defense(result: DefenseInput) -> void:
	defense_window_closed.emit(result)


## Deals [param raw_damage] to character stats after checking blocks.
@warning_ignore("unused_parameter")
func take_dmg(raw_damage: int, blocked: bool) -> void:
	stats.change_health(-raw_damage)
	if stats.health <= 0:
		health_depleted.emit()


# Modulates sprite scale to reflect team-facing direction.
func _update_facing_direction() -> void:
	var tm := team_manager
	if tm and tm.team == TeamManager.Team.Enemy:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	else:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
