@abstract class_name CharacterAction extends Node

## Abstract base for anything a character commits during one turn.
##
## A turn action resolves via [method resolve]. Non-combat actions (wait,
## support, item) apply their effects directly; [CombatAction] wraps an
## [AttackString] and plays it against a target.

## True when this action commits against the actor itself without entering
## target selection.
@export var targets_self: bool = false


## Resolves this action for [param actor] against [param target].
## Async - may await animations or interactive windows.
@abstract func resolve(
	actor: Character,
	target: Character
) -> void
