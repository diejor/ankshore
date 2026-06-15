class_name CombatAction extends CharacterAction

## A character action that plays a player-built [AttackString] against a
## target.
##
## Wraps an [member attack_string] assembled during planning.

## Maximum beats the attacker may append while building the string.
@export var max_beats: int = 4

## Seconds the attacker has to build the string before it auto-seals.
@export var build_time_sec: float = 2.0

## Beats assembled during planning. Set at commit, cleared after
## resolution.
var attack_string: AttackString = null


func resolve(
	actor: Character,
	targets: Array[Character],
	ctx: PhaseContext
) -> void:
	if attack_string == null:
		return
	var defender := _first_live(targets)
	if defender == null:
		return
	await attack_string.resolve(actor, defender, ctx)


func _first_live(targets: Array[Character]) -> Character:
	for target in targets:
		if target and target.is_alive():
			return target
	return null
