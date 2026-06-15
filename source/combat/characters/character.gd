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
signal move_resolved(move: CombatAction, hit: bool, damage: int)
signal pending_move_changed(move: CombatAction)
signal pending_target_changed(target: Character)

@export var stats: CharacterStats = CharacterStats.new()
@export var move_list: Array[CombatAction] = []

## Move selected for this character's next resolution step. For an attack
## this is the [member AttackString.move]; see [member pending_string].
var pending_move: CombatAction = null

## Player-built attack to resolve this turn, or [code]null[/code] for a
## non-attack move. When set, [method execute_turn] runs the string
## resolver instead of [member pending_move].
var pending_string: AttackString = null

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
static var _WAIT_ACTION: WaitAction = WaitAction.new()
var _defense_window_active: bool = false


func _ready() -> void:
	_update_facing_direction()


## Returns all [CombatAction] nodes attached as direct children plus
## any actions in [member move_list], without duplicates. Used by
## [MoveListContainer] to render the move-pick view.
func available_moves() -> Array[CombatAction]:
	var result: Array[CombatAction] = [_WAIT_ACTION]
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


## Stores a non-attack move and targets this character will execute.
func commit_move(move: CombatAction, targets: Array[Character]) -> void:
	pending_string = null
	pending_move = move
	pending_targets = targets.duplicate()
	pending_move_changed.emit(pending_move)
	pending_target_changed.emit(_first_pending_target())


## Stores a player-built [param attack] and its targets for this turn.
## [member pending_move] mirrors the string's capping move for previews.
func commit_attack(
	attack: AttackString, targets: Array[Character]
) -> void:
	pending_string = attack
	pending_move = attack.move
	pending_targets = targets.duplicate()
	pending_move_changed.emit(pending_move)
	pending_target_changed.emit(_first_pending_target())


## Clears the move, string, and targets committed for this turn.
func clear_pending_move() -> void:
	pending_move = null
	pending_string = null
	pending_targets = []
	pending_move_changed.emit(null)
	pending_target_changed.emit(null)


## Resolves the pending attack string or move, then clears turn data.
func execute_turn(ctx: PhaseContext) -> void:
	if pending_string and pending_string.move:
		var defender := _first_live_target()
		if defender:
			var resolver := AttackStringResolver.new(
				ctx, self, defender, pending_string
			)
			await resolver.run()
	elif pending_move != null:
		await pending_move.execute_async(self, pending_targets, ctx)
	clear_pending_move()


## Opens a defense window and awaits the defending controller's result.
func request_defense(
	kind: DefenseKind,
	beat: AttackBeat,
	window_sec: float
) -> DefenseInput:
	_defense_window_active = true
	defense_window_opened.emit(kind, beat, window_sec)
	get_tree().create_timer(window_sec).timeout.connect(
		_complete_defense_timeout
	)
	var result: DefenseInput = await defense_window_closed
	_defense_window_active = false
	if result == null:
		return DefenseInput.none()
	return result


## Reports the defender's reaction back to the resolver.
func complete_defense(result: DefenseInput) -> void:
	if not _defense_window_active:
		return
	defense_window_closed.emit(result)


## Deals [param raw_damage] to character stats after checking blocks.
@warning_ignore("unused_parameter")
func take_dmg(raw_damage: int, blocked: bool) -> void:
	stats.change_health(-raw_damage)
	if stats.health <= 0:
		health_depleted.emit()


# Returns the first selected target for single-target views.
func _first_pending_target() -> Character:
	for target in pending_targets:
		if target:
			return target
	return null


# Returns the first living target, used when resolving an attack string.
func _first_live_target() -> Character:
	for target in pending_targets:
		if target and target.is_alive():
			return target
	return null


# Closes unanswered defense windows so resolution cannot stall.
func _complete_defense_timeout() -> void:
	if _defense_window_active:
		complete_defense(DefenseInput.none())


# Modulates sprite scale to reflect team-facing direction.
func _update_facing_direction() -> void:
	var tm := team_manager
	if tm and tm.team == TeamManager.Team.Enemy:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
	else:
		@warning_ignore("unsafe_property_access")
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
