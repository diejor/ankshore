class_name AttackStringResolver extends RefCounted

## Runs one [AttackString] from telegraph to ender resolution.
##
## Owns the per-string interactive loop: for each beat it plays the
## attacker's windup, samples a [DefenseInput] from the defender's
## [TeamController], applies hit-or-block damage via the existing
## [method CharacterStats.damage_taken] path, then resolves the ender
## (strike or grab) the same way. Once the defender takes one unblocked
## hit, [member StringState.combo_locked] short-circuits later defense
## windows so the remaining beats confirm at full damage.
##
## [ResolutionPhase] knows nothing about this class - it sees
## [method AttackString.execute_async] like any other [CombatAction].

signal beat_telegraphed(beat: AttackBeat)
signal beat_resolved(beat: AttackBeat, blocked: bool, damage: int)
signal ender_resolved(ender: int, hit: bool, damage: int)

var _ctx: PhaseContext
var _attacker: Character
var _defender: Character
var _string: AttackString
var _state: StringState


func _init(
	ctx: PhaseContext,
	p_attacker: Character,
	p_defender: Character,
	p_string: AttackString,
) -> void:
	_ctx = ctx
	_attacker = p_attacker
	_defender = p_defender
	_string = p_string
	_state = StringState.new()


## Drives the string. Awaits each beat plus the ender in order. Returns
## once damage has been applied and animations resolved.
func run() -> void:
	for beat in _string.beats:
		if not _defender.is_alive():
			return
		await _resolve_beat(beat)
	if _defender.is_alive():
		await _resolve_ender()


func _resolve_beat(beat: AttackBeat) -> void:
	beat_telegraphed.emit(beat)
	var d_state := _defender_state()
	if d_state:
		d_state.beat_telegraphed.emit(beat)
	await _play_windup(beat)

	var blocked: bool
	if _state.combo_locked:
		blocked = false
	else:
		var input := await _await_block(beat)
		blocked = input.matches_beat(beat)

	var dmg: int = _apply_beat_damage(beat, blocked)
	if not blocked:
		_state.combo_locked = true
		_state.hits_landed += 1
	else:
		_state.chip_dealt += dmg
	beat_resolved.emit(beat, blocked, dmg)
	if d_state:
		d_state.beat_resolved.emit(beat, blocked, dmg)


func _resolve_ender() -> void:
	match _string.ender:
		AttackString.Ender.STRIKE:
			await _resolve_strike_ender()
		AttackString.Ender.GRAB:
			await _resolve_grab_ender()


func _resolve_strike_ender() -> void:
	# A strike ender follows the same block rules as a beat - the
	# defender must read the final beat's side. We synthesize a virtual
	# beat for the read so habits/AI use the same path.
	var virtual_beat := AttackBeat.new()
	virtual_beat.damage = _string.strike_damage
	virtual_beat.direction = (
		_string.beats.back().direction
		if not _string.beats.is_empty()
		else AttackBeat.Direction.OVERHEAD
	)
	virtual_beat.side = (
		_string.beats.back().side
		if not _string.beats.is_empty()
		else AttackBeat.StrikeSide.FRONT
	)
	virtual_beat.react_window_sec = _string.parry_window_sec

	var blocked: bool
	if _state.combo_locked:
		blocked = false
	else:
		var input := await _await_block(virtual_beat)
		blocked = input.matches_beat(virtual_beat)

	var dmg: int = _apply_beat_damage(virtual_beat, blocked)
	if not blocked:
		_state.combo_locked = true
		_state.hits_landed += 1
	ender_resolved.emit(AttackString.Ender.STRIKE, not blocked, dmg)
	var d_state := _defender_state()
	if d_state:
		d_state.ender_resolved.emit(
			AttackString.Ender.STRIKE, not blocked, dmg
		)


func _resolve_grab_ender() -> void:
	# A grab ignores the combo-confirm rule - even a hit-confirmed
	# defender can still parry the grab.
	var input := await _await_parry(_string.parry_window_sec)
	var parried := input.kind == DefenseInput.Kind.PARRY

	var d_state := _defender_state()
	if parried:
		var counter: int = _apply_counter_damage(_string.parry_counter_damage)
		ender_resolved.emit(AttackString.Ender.GRAB, false, counter)
		if d_state:
			d_state.ender_resolved.emit(
				AttackString.Ender.GRAB, false, counter
			)
	else:
		var dmg: int = _apply_grab_damage(_string.grab_damage)
		_state.hits_landed += 1
		ender_resolved.emit(AttackString.Ender.GRAB, true, dmg)
		if d_state:
			d_state.ender_resolved.emit(
				AttackString.Ender.GRAB, true, dmg
			)


func _apply_beat_damage(beat: AttackBeat, blocked: bool) -> int:
	if not _defender or not _defender.stats:
		return 0
	var raw: int = beat.damage + _attacker.stats.damage
	if blocked:
		@warning_ignore("unsafe_call_argument")
		raw = int(round(raw * beat.chip_pct))
	var final: int = _defender.stats.damage_taken(raw, blocked)
	_defender.take_dmg(final, blocked)
	return final


func _apply_grab_damage(amount: int) -> int:
	if not _defender or not _defender.stats:
		return 0
	var raw: int = amount + _attacker.stats.damage
	var final: int = _defender.stats.damage_taken(raw, false)
	_defender.take_dmg(final, false)
	return final


func _apply_counter_damage(amount: int) -> int:
	if not _attacker or not _attacker.stats:
		return 0
	var raw: int = amount + _defender.stats.damage
	var final: int = _attacker.stats.damage_taken(raw, false)
	_attacker.take_dmg(final, false)
	return final


## Brief pause representing the attacker's windup. Per-direction clips
## (e.g. [code]&"attack_overhead"[/code]) will plug in here once authored;
## for now we just yield enough time for the defender to read the beat.
func _play_windup(_beat: AttackBeat) -> void:
	var tree := _ctx.turn_manager.get_tree() if _ctx.turn_manager else null
	if tree:
		await tree.create_timer(0.15).timeout


# Opens a block window on the defender's [TeamState] and awaits the
# matching close signal. Returns [method DefenseInput.none] if there is
# no bound state (defender outside a managed team, e.g. a test fixture).
func _await_block(beat: AttackBeat) -> DefenseInput:
	var s := _defender_state()
	if s == null:
		return DefenseInput.none()
	s.request_block(beat, beat.react_window_sec)
	var result: DefenseInput = await s.defense_window_closed
	if result == null:
		return DefenseInput.none()
	return result


# Opens a parry window on the defender's [TeamState] and awaits close.
func _await_parry(window_sec: float) -> DefenseInput:
	var s := _defender_state()
	if s == null:
		return DefenseInput.none()
	s.request_parry(window_sec)
	var result: DefenseInput = await s.defense_window_closed
	if result == null:
		return DefenseInput.none()
	return result


# Resolves the defender's [TeamState] via its [TeamManager].
func _defender_state() -> TeamState:
	if _defender == null:
		return null
	var tm := _defender.team_manager
	return tm.state if tm else null


## Per-string mutable state. Lives only for one [method run] invocation.
class StringState extends RefCounted:
	## True after the defender takes one unblocked hit. Subsequent beats
	## skip the input window and auto-land at full damage.
	var combo_locked: bool = false

	## Beats and ender that landed unblocked.
	var hits_landed: int = 0

	## Cumulative chip damage dealt through blocks.
	var chip_dealt: int = 0
