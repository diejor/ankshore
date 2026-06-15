class_name AttackString extends Resource

## A player-built sequence of [AttackBeat]s, resolved against a defender.
##
## Wrapped by a [CombatAction] and assembled interactively during
## planning. Owns its own resolution: for each beat it samples the
## defender's block read and applies hit or chip damage. Once the defender
## takes one unblocked hit the combo locks and the remaining beats confirm
## at full damage. Constructed at runtime; never authored as a
## [code].tres[/code].

## Ordered beats played in turn against the defender.
@export var beats: Array[AttackBeat] = []

var chipDamage: float  = .1

## Plays the string against [param defender], awaiting each beat's defense
## window. Returns once damage has been applied.
func resolve(attacker: Character, defender: Character) -> void:
	var combo_locked := false
	for beat in beats:
		if not defender.is_alive():
			return
		defender.beat_telegraphed.emit(beat)
		await _windup(defender)
		var blocked: bool
		if combo_locked:
			blocked = false
		else:
			var input := await defender.request_defense(
				beat, beat.react_window_sec
			)
			blocked = input.matches_beat(beat)
		var dmg := _apply_damage(attacker, defender, beat, blocked)
		if defender.is_alive():
			if blocked:
				defender.play_block()
			else:
				defender.play_hit()
		if not blocked:
			combo_locked = true
		defender.beat_resolved.emit(beat, blocked, dmg)


# Applies a beat's damage to the defender, reduced to chip on a block.
func _apply_damage(
	attacker: Character,
	defender: Character,
	beat: AttackBeat,
	blocked: bool
) -> int:
	if defender.stats == null:
		return 0
	var raw: int = beat.damage + attacker.stats.damage
	if blocked:
		@warning_ignore("unsafe_call_argument")
		raw = int(round(raw * beat.chip_pct))
	var final: int = defender.stats.damage_taken(raw, blocked)
	defender.take_dmg(final, blocked)
	return final


# Brief windup pause before each beat resolves.
func _windup(defender: Character) -> void:
	var tree := defender.get_tree()
	if tree:
		await tree.create_timer(0.08).timeout
