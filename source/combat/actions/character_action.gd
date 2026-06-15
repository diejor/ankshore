@abstract class_name CharacterAction extends Node

## Abstract base for anything a character commits during one turn.
##
## A turn action resolves via [method resolve]. Non-combat actions (wait,
## support) apply their effects directly; [CombatAction] wraps an
## [AttackString] and plays it against a target.

## True when this action commits against the actor itself without entering
## target selection.
@export var targets_self: bool = false


## Resolves this action for [param actor] against [param target].
## Async - may await animations or interactive windows.
func resolve(
	_actor: Character,
	_target: Character #can encapulate multiple targets if character is registered as multiple in other scripts
) -> void:
	await get_tree().create_timer(0.1).timeout
