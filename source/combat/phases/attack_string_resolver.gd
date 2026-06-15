class_name AttackStringResolver extends RefCounted

## Runs one [AttackString] from telegraph to move resolution.
##
## Owns the per-string interactive loop: for each beat it plays the
## attacker's windup, samples a [DefenseInput] from the defender's
## [TeamController], applies hit-or-block damage via the existing
## [method CharacterStats.damage_taken] path, then hands off to the
## string's capping move via [method CombatAction.resolve]. Once the
## defender takes one unblocked hit, [member StringState.combo_locked]
## short-circuits later defense windows so the remaining beats confirm at
## full damage.
## [br][br]
## Attack moves call back into the public surface ([member attacker],
## [member defender], [member state] and the [code]apply_*_damage[/code]
## helpers) to resolve their closing read. Observers bind to the
## defender's combat signals; this resolver has no public signal surface.

var ctx: PhaseContext
var attacker: Character
var defender: Character
var state: StringState

var _string: AttackString


func _init(
	p_ctx: PhaseContext,
	p_attacker: Character,
	p_defender: Character,
	p_string: AttackString,
) -> void:
	ctx = p_ctx
	attacker = p_attacker
	defender = p_defender
	_string = p_string
	state = StringState.new()


## Drives the string. Awaits each beat then the capping move in order.
## Returns once damage has been applied and animations resolved.
func run() -> void:
	for beat in _string.beats:
		if not defender.is_alive():
			return
		await _resolve_beat(beat)
	if defender.is_alive() and _string.move:
		await _string.move.resolve(self)


## The last beat in the string, or [code]null[/code] when empty. Used by
## attack moves that mirror the string's trailing mix.
func last_beat() -> AttackBeat:
	if _string.beats.is_empty():
		return null
	return _string.beats.back()


## Applies [param beat]'s damage to the defender, reduced to chip when
## [param blocked]. Returns the final amount dealt.
func apply_beat_damage(beat: AttackBeat, blocked: bool) -> int:
	if not defender or not defender.stats:
		return 0
	var raw: int = beat.damage + attacker.stats.damage
	if blocked:
		@warning_ignore("unsafe_call_argument")
		raw = int(round(raw * beat.chip_pct))
	var final: int = defender.stats.damage_taken(raw, blocked)
	defender.take_dmg(final, blocked)
	return final


## Applies an unblockable [param amount] to the defender (grab hit).
func apply_grab_damage(amount: int) -> int:
	if not defender or not defender.stats:
		return 0
	var raw: int = amount + attacker.stats.damage
	var final: int = defender.stats.damage_taken(raw, false)
	defender.take_dmg(final, false)
	return final


## Applies a parry counter of [param amount] back to the attacker.
func apply_counter_damage(amount: int) -> int:
	if not attacker or not attacker.stats:
		return 0
	var raw: int = amount + defender.stats.damage
	var final: int = attacker.stats.damage_taken(raw, false)
	attacker.take_dmg(final, false)
	return final


func _resolve_beat(beat: AttackBeat) -> void:
	defender.beat_telegraphed.emit(beat)
	await _play_windup(beat)

	var blocked: bool
	if state.combo_locked:
		blocked = false
	else:
		var input := await defender.request_defense(
			Character.DefenseKind.BLOCK,
			beat,
			beat.react_window_sec
		)
		blocked = input.matches_beat(beat)

	var dmg: int = apply_beat_damage(beat, blocked)
	if not blocked:
		state.combo_locked = true
		state.hits_landed += 1
	else:
		state.chip_dealt += dmg
	defender.beat_resolved.emit(beat, blocked, dmg)


## Brief pause representing the attacker's windup. Per-direction clips
## will plug in here once authored; for now we just yield enough time for
## the defender to read the beat.
func _play_windup(_beat: AttackBeat) -> void:
	var tree := ctx.turn_manager.get_tree() if ctx.turn_manager else null
	if tree:
		await tree.create_timer(0.15).timeout


## Per-string mutable state. Lives only for one [method run] invocation.
class StringState extends RefCounted:
	## True after the defender takes one unblocked hit. Subsequent beats
	## skip the input window and auto-land at full damage.
	var combo_locked: bool = false

	## Beats and capping move that landed unblocked.
	var hits_landed: int = 0

	## Cumulative chip damage dealt through blocks.
	var chip_dealt: int = 0
