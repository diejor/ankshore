class_name Character extends Node2D

## Represents a participant in a combat encounter on the battlefield.

@warning_ignore("unused_signal")
signal action_finished(action: CharacterAction)
signal health_depleted
@warning_ignore("unused_signal")
signal will_depleted
@warning_ignore("unused_signal")
signal courage_depleted
signal defense_window_opened(beat: AttackBeat, window_sec: float)
signal defense_window_closed(result: DefenseInput)
@warning_ignore("unused_signal")
signal beat_telegraphed(beat: AttackBeat)
@warning_ignore("unused_signal")
signal beat_resolved(beat: AttackBeat, blocked: bool, damage: int)
signal pending_action_changed(action: CharacterAction)
signal pending_target_changed(target: Character)

@export var stats: CharacterStats = CharacterStats.new()
@export var move_list: Array[CharacterAction] = []

## Runtime handle used for attack travel targeting.
@onready var combat_handle: CombatHandle = $CombatHandle

@onready var _body: Node2D = $Body
@onready var _anim: AnimationPlayer = $AnimationPlayer

## Action selected for this character's next resolution step.
var pending_action: CharacterAction = null

## Target selected for [member pending_action].
var pending_target: Character = null

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
	play_idle()


## Returns all [CharacterAction] nodes attached as direct children plus
## any actions in [member move_list], without duplicates. Used by
## [MoveListContainer] to render the move-pick view.
func available_moves() -> Array[CharacterAction]:
	var result: Array[CharacterAction] = [_WAIT_ACTION]
	for child in get_children():
		if child is CharacterAction:
			result.append(child)
	for action in move_list:
		if action and not result.has(action):
			result.append(action)
	return result


## True when [member stats] are present and [member CharacterStats.health]
## is positive.
func is_alive() -> bool:
	return stats != null and stats.health > 0


## Stores the action and target this character will resolve this turn.
## For a [CombatAction], pass the player-built [param attack_string].
func commit_action(
	action: CharacterAction,
	target: Character,
	attack_string: AttackString = null
) -> void:
	pending_action = action
	pending_target = target
	if action is CombatAction:
		(action as CombatAction).attack_string = attack_string
	pending_action_changed.emit(pending_action)
	pending_target_changed.emit(pending_target)


## Clears the action and target committed for this turn.
func clear_pending_action() -> void:
	if pending_action is CombatAction:
		(pending_action as CombatAction).attack_string = null
	pending_action = null
	pending_target = null
	pending_action_changed.emit(null)
	pending_target_changed.emit(null)


## Resolves [member pending_action], then clears the pending turn data.
func execute_turn() -> void:
	if pending_action:
		if pending_action is CombatAction and pending_target:
			await play_attack(pending_target)
		await pending_action.resolve(self, pending_target)
	clear_pending_action()


## Plays the default combat idle loop.
func play_idle() -> void:
	if _anim:
		_anim.play("idle")


## Lunges this character toward [param target] while playing the local
## attack clip.
func play_attack(target: Character) -> void:
	if target == null or target.combat_handle == null:
		return
	combat_handle.begin_travel(target.combat_handle)
	_anim.play("attack")
	if _anim.is_playing():
		await _anim.animation_finished
	combat_handle.end_travel()
	play_idle()


## Plays the hit reaction clip, then returns to idle.
func play_hit() -> void:
	_play_reaction("hit")


## Plays the block reaction clip, then returns to idle.
func play_block() -> void:
	_play_reaction("block")


## Plays the death clip and leaves the character in its final pose.
func play_die() -> void:
	if _anim:
		_anim.play("die")
		await _anim.animation_finished


## Opens a block-read window for [param beat] and awaits the defending
## controller's result.
func request_defense(beat: AttackBeat, window_sec: float) -> DefenseInput:
	_defense_window_active = true
	defense_window_opened.emit(beat, window_sec)
	get_tree().create_timer(window_sec).timeout.connect(
		_complete_defense_timeout
	)
	var result: DefenseInput = await defense_window_closed
	_defense_window_active = false
	if result == null:
		return DefenseInput.none()
	return result


## Reports the defender's reaction back to the resolving string.
func complete_defense(result: DefenseInput) -> void:
	if not _defense_window_active:
		return
	defense_window_closed.emit(result)


## Deals [param raw_damage] to character stats after checking blocks.
@warning_ignore("unused_parameter")
func take_dmg(raw_damage: int, blocked: bool) -> void:
	stats.change_health(-raw_damage)
	if stats.health <= 0:
		play_die()
		health_depleted.emit()





# Closes unanswered defense windows so resolution cannot stall.
func _complete_defense_timeout() -> void:
	if _defense_window_active:
		complete_defense(DefenseInput.none())


# Modulates body scale to reflect team-facing direction.
func _update_facing_direction() -> void:
	var tm := team_manager
	if tm and tm.team == TeamManager.Team.Enemy:
		@warning_ignore("unsafe_property_access")
		_body.scale.x = -abs(_body.scale.x)
	else:
		@warning_ignore("unsafe_property_access")
		_body.scale.x = abs(_body.scale.x)


# Plays a short reaction and returns to idle if no other clip took over.
func _play_reaction(anim_name: StringName) -> void:
	if _anim == null:
		return
	_anim.play(anim_name)
	await _anim.animation_finished
	if _anim.current_animation == anim_name:
		play_idle()
