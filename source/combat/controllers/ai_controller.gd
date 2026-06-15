class_name AIController extends TeamController

## [TeamController] driven by an automated policy.
##
## Reacts to [TeamState] phase changes by computing a decision and
## calling the relevant mutation method. Defense windows are answered
## with a probability roll.

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
	if not team.character_defense_window_opened.is_connected(
		_on_defense_window_opened
	):
		team.character_defense_window_opened.connect(
			_on_defense_window_opened
		)
	_on_phase_changed(state.phase)


func _on_phase_changed(phase: TeamState.Phase) -> void:
	match phase:
		TeamState.Phase.PICKING_CHARACTER:
			_pick_character.call_deferred()
		TeamState.Phase.PICKING_MOVE:
			_pick_move.call_deferred()
		TeamState.Phase.PICKING_TARGETS:
			_pick_targets.call_deferred()
		TeamState.Phase.BUILDING_STRING:
			_build_string.call_deferred()


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


# Assembles a random beat string up to the finisher's beat cap.
func _build_string() -> void:
	await _think()
	if state.phase != TeamState.Phase.BUILDING_STRING:
		return
	var move := state.selected_move
	var cap: int = move.max_beats if move else 0
	var beats: Array[AttackBeat] = []
	for _i in randi_range(1, max(1, cap)):
		var beat := AttackBeat.new()
		beat.direction = (
			AttackBeat.Direction.OVERHEAD if randf() < 0.5
			else AttackBeat.Direction.LOW
		)
		beat.side = (
			AttackBeat.StrikeSide.FRONT if randf() < 0.5
			else AttackBeat.StrikeSide.BEHIND
		)
		beats.append(beat)
	state.commit_string(beats)


func _on_defense_window_opened(
	character: Character,
	kind: Character.DefenseKind,
	beat: AttackBeat,
	window_sec: float
) -> void:
	if kind == Character.DefenseKind.PARRY:
		_react_parry.call_deferred(character, window_sec)
	else:
		_react_block.call_deferred(character, beat, window_sec)


# Picks a block direction; wrong guesses miss on the vertical axis.
func _react_block(
	defender: Character,
	beat: AttackBeat,
	window_sec: float
) -> void:
	await get_tree().create_timer(window_sec * 0.5).timeout
	if defender == null:
		return
	if randf() < block_skill:
		defender.complete_defense(
			DefenseInput.block(beat.direction, beat.side)
		)
		return
	var wrong_dir: AttackBeat.Direction = (
		AttackBeat.Direction.LOW
		if beat.direction == AttackBeat.Direction.OVERHEAD
		else AttackBeat.Direction.OVERHEAD
	)
	defender.complete_defense(DefenseInput.block(wrong_dir, beat.side))


# Rolls against [member parry_skill] for the grab ender.
func _react_parry(defender: Character, window_sec: float) -> void:
	await get_tree().create_timer(window_sec * 0.5).timeout
	if defender == null:
		return
	if randf() < parry_skill:
		defender.complete_defense(DefenseInput.parry())
	else:
		defender.complete_defense(DefenseInput.none())


# Yields long enough for the player to read the AI's decision.
func _think() -> void:
	if think_delay_sec > 0.0:
		await get_tree().create_timer(think_delay_sec).timeout
