class_name Strike extends CombatAction

## An attack move that caps a string with a strike following the same
## block rules as a beat.
##
## The defender must read the strike's mix - synthesized from the last
## beat's direction and side - within [member read_window_sec], unless
## [member AttackStringResolver.StringState.combo_locked] already forced a
## confirm.

## Damage of the strike on hit, before attacker stat bonuses.
@export var strike_damage: int = 20

## Seconds the defender has to read the strike.
@export var read_window_sec: float = 0.6


func _init() -> void:
	name = "Strike"
	max_beats = 4
	build_time_sec = 2.0


func builds_attack_string() -> bool:
	return true


func resolve(resolver: AttackStringResolver) -> void:
	var virtual_beat := AttackBeat.new()
	virtual_beat.damage = strike_damage
	var last := resolver.last_beat()
	virtual_beat.direction = (
		last.direction if last else AttackBeat.Direction.OVERHEAD
	)
	virtual_beat.side = (
		last.side if last else AttackBeat.StrikeSide.FRONT
	)
	virtual_beat.react_window_sec = read_window_sec

	var blocked: bool
	if resolver.state.combo_locked:
		blocked = false
	else:
		var input := await resolver.defender.request_defense(
			Character.DefenseKind.BLOCK,
			virtual_beat,
			virtual_beat.react_window_sec
		)
		blocked = input.matches_beat(virtual_beat)

	var dmg: int = resolver.apply_beat_damage(virtual_beat, blocked)
	if not blocked:
		resolver.state.combo_locked = true
		resolver.state.hits_landed += 1
	resolver.defender.move_resolved.emit(self, not blocked, dmg)
