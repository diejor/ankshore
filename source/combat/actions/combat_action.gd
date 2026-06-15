class_name CombatAction extends Node

## Base class representing move data that can resolve during a turn.
##
## A move either resolves directly via [method execute_async] (support,
## item, wait) or, when [method builds_attack_string] is true, caps a
## player-built [AttackString] and resolves against a defender via
## [method resolve]. [member max_beats] and [member build_time_sec] bound
## the string-building step for attack moves.

## True when this action should commit against the actor itself without
## entering target selection.
@export var targets_self: bool = false

## Maximum beats the attacker may append before this move. Used only when
## [method builds_attack_string] is true.
@export var max_beats: int = 0

## Seconds the attacker has to build the string before it auto-seals.
## Used only when [method builds_attack_string] is true.
@export var build_time_sec: float = 0.0


## True when picking this move enters the interactive string-building
## step and resolves via [method resolve] against a defender. Non-attack
## moves leave this false and resolve via [method execute_async].
func builds_attack_string() -> bool:
	return false


## Synchronous entry point. Subclasses apply gameplay effects here
## (healing, buff application). Animation playback belongs in
## [method execute_async], not here.
func execute(_actor: Character, _targets: Array[Character]) -> void:
	pass


## Async entry point for non-attack moves. Applies effects via
## [method execute]. This [code]await[/code] seam is where per-move
## animation playback will plug back in.
func execute_async(
	actor: Character,
	targets: Array[Character],
	_ctx: PhaseContext
) -> void:
	execute(actor, targets)


## Resolves this move as the cap of an [AttackString], reading the
## defender's reaction. Override in attack moves; non-attack moves never
## reach this path. Async - awaits the defender's reaction window.
func resolve(_resolver: AttackStringResolver) -> void:
	await get_tree().create_timer(0.1).timeout
	pass
