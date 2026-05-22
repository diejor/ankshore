class_name AIController extends TeamController

## [TeamController] driven by an automated policy.
##
## Reacts to [TeamState] phase changes by computing a decision and
## calling the relevant mutation method, so the team plans without any
## UI or input. Defense windows are answered with a probability roll.

## Probability the AI picks the correct block direction during a
## defense window. Tunable per encounter.
@export_range(0.0, 1.0) var block_skill: float = 0.5

## Probability the AI lands a parry against a grab ender.
@export_range(0.0, 1.0) var parry_skill: float = 0.3

## Seconds the AI waits before responding to a phase change. Provides
## human-readable pacing in lieu of a real animation track.
@export var think_delay_sec: float = 0.25


func _ready() -> void:
	if state == null:
		push_error("AIController has no bound TeamState.")
		return
	state.phase_changed.connect(_on_phase_changed)
	state.defense_window_opened.connect(_on_defense_window_opened)
	state.parry_window_opened.connect(_on_parry_window_opened)
	_on_phase_changed(state.phase)


func _on_phase_changed(phase: TeamState.Phase) -> void:
	match phase:
		TeamState.Phase.PICKING_CHARACTER:
			_pick_character.call_deferred()
		TeamState.Phase.PICKING_MOVE:
			_pick_move.call_deferred()
		TeamState.Phase.PICKING_TARGETS:
			_pick_targets.call_deferred()


# Picks the first pending character. No prioritization yet.
func _pick_character() -> void:
	await _think()
	if state.phase != TeamState.Phase.PICKING_CHARACTER:
		return
	if state.pending_characters.is_empty():
		return
	state.select_character(state.pending_characters[0])


# Picks the first available move on the active character.
func _pick_move() -> void:
	await _think()
	if state.phase != TeamState.Phase.PICKING_MOVE:
		return
	var actor := state.active_character
	if actor == null:
		return
	var moves := actor.available_moves()
	if moves.is_empty():
		return
	state.select_move(moves[0])


# Picks the first live enemy character as the target.
func _pick_targets() -> void:
	await _think()
	if state.phase != TeamState.Phase.PICKING_TARGETS:
		return
	var enemy := team.get_other_team() if team else null
	if enemy == null:
		return
	for slot in enemy.slots:
		var c := slot.get_character()
		if c and c.is_alive():
			state.commit_targets([c])
			return


func _on_defense_window_opened(
	beat: AttackBeat, window_sec: float
) -> void:
	_react_block.call_deferred(beat, window_sec)


func _on_parry_window_opened(window_sec: float) -> void:
	_react_parry.call_deferred(window_sec)


# Picks a block direction; wrong guesses miss on the vertical axis.
func _react_block(beat: AttackBeat, window_sec: float) -> void:
	await get_tree().create_timer(window_sec * 0.5).timeout
	if randf() < block_skill:
		state.complete_defense(
			DefenseInput.block(beat.direction, beat.side)
		)
		return
	var wrong_dir: AttackBeat.Direction = (
		AttackBeat.Direction.LOW
		if beat.direction == AttackBeat.Direction.OVERHEAD
		else AttackBeat.Direction.OVERHEAD
	)
	state.complete_defense(DefenseInput.block(wrong_dir, beat.side))


# Rolls against [member parry_skill] for the grab ender.
func _react_parry(window_sec: float) -> void:
	await get_tree().create_timer(window_sec * 0.5).timeout
	if randf() < parry_skill:
		state.complete_defense(DefenseInput.parry())
	else:
		state.complete_defense(DefenseInput.none())


# Yields long enough for the player to read the AI's decision.
func _think() -> void:
	if think_delay_sec > 0.0:
		await get_tree().create_timer(think_delay_sec).timeout
