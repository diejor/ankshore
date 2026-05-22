class_name AttackString extends CombatAction

## A sequence of [AttackBeat]s closed by a strike or grab ender.
##
## The canonical attacking move. [method execute_async] delegates to
## [AttackStringResolver], which runs
## the interactive defense loop against the targeted character's
## controller. [ResolutionPhase] sees this just like any other
## [CombatAction] - the per-beat interaction lives behind this override.

enum Ender { STRIKE, GRAB }

## Ordered beats played in turn against the defender.
@export var beats: Array[AttackBeat] = []

## How the string closes. STRIKE follows the same block rules as the
## preceding beats; GRAB requires a parry instead.
@export var ender: Ender = Ender.STRIKE

## Damage of the strike ender, used when [member ender] is
## [constant Ender.STRIKE]. Mixed via the last beat's [member AttackBeat.side].
@export var strike_damage: int = 20

## Damage of the grab ender on hit (defender failed to parry).
@export var grab_damage: int = 30

## Damage dealt back to the attacker on a successful parry.
@export var parry_counter_damage: int = 25

## Seconds the defender has to parry a grab.
@export var parry_window_sec: float = 0.6


## Hands resolution to [AttackStringResolver] for the first live target.
## Multi-target strings are out of scope - the first valid defender wins.
func execute_async(ctx: PhaseContext) -> void:
	var defender: Character = _first_live_target()
	if not attacker or not defender:
		return
	var resolver := AttackStringResolver.new(ctx, attacker, defender, self)
	await resolver.run()


func animation_key() -> StringName:
	return &"attack_string"


func _first_live_target() -> Character:
	for target in targets:
		if target and target.is_alive():
			return target
	return null
