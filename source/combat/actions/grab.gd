class_name Grab extends CombatAction

## An attack move that caps a string with a grab, ignoring the
## combo-confirm rule.
##
## Even a hit-confirmed defender may still parry the grab within
## [member parry_window_sec]. A parry deals [member parry_counter_damage]
## back to the attacker; a missed parry takes [member grab_damage].

## Damage of the grab on hit, before attacker stat bonuses.
@export var grab_damage: int = 30

## Damage dealt back to the attacker on a successful parry.
@export var parry_counter_damage: int = 25

## Seconds the defender has to parry the grab.
@export var parry_window_sec: float = 0.6


func _init() -> void:
	name = "Grab"
	max_beats = 4
	build_time_sec = 2.0


func builds_attack_string() -> bool:
	return true


func resolve(resolver: AttackStringResolver) -> void:
	var input := await resolver.defender.request_defense(
		Character.DefenseKind.PARRY, null, parry_window_sec
	)
	var parried := input.kind == DefenseInput.Kind.PARRY

	if parried:
		var counter: int = resolver.apply_counter_damage(parry_counter_damage)
		resolver.attacker.move_resolved.emit(self, false, counter)
		resolver.defender.move_resolved.emit(self, false, 0)
	else:
		var dmg: int = resolver.apply_grab_damage(grab_damage)
		resolver.state.hits_landed += 1
		resolver.defender.move_resolved.emit(self, true, dmg)
