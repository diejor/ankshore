class_name CombatAction extends CharacterAction

## A character action that plays a preset [AttackString] against a
## target and performs a move.
##
## Wraps an [member attack_string] assembled during planning.

## Maximum beats the attacker may append while building the string.
@export var max_beats: int = 4

@export var damage_scale: int = 20

## Seconds the attacker has to build the string before it auto-seals.
@export var build_time_sec: float = 2.0

## Beats assembled during planning. Set at commit, cleared after
## resolution.
var attack_string: AttackString = null

## Holds different attack strings for the move
@export var variations: Array[AttackString]

## chip dmg calculator, showcases amount of damage converted to chip whenever opponent is blocked
@export var chipCalculation :float = .1

## The amount of will used up when performing a move. Base Will usage will be 0.
@export var will_cost: int

## speed of attack
var attack_speed: float

var chip_damage_modifier: float

## performs the actions of the attack string and the move
func resolve(actor: Character, target: Character) -> void:
	if attack_string == null:
		return
	if target == null or not target.is_alive():
		return
	attack_string.chipDamage = chipCalculation
	await attack_string.resolve(actor, target)
	#perform move after here
