class_name CombatAction extends Node

## Base class representing an executable action during a turn.
##
## All specific actions (Attack, Support, Item) inherit from this class.

## The entity initiating this action.
var attacker: Character

## List of target entities for this action.
@export var targets: Array[Character] = []


## Synchronous entry point. Subclasses apply gameplay effects here
## (damage, healing, buff application). Animation playback belongs in
## [method execute_async], not here.
func execute() -> void:
	pass


## Plays the actor's animation for this action and awaits its
## completion, then applies effects via [method execute]. Override to
## customise sequencing (e.g. apply damage on impact frame).
func execute_async(ctx: PhaseContext) -> void:
	var animator: PhaseAnimator = (
		ctx.animator_for(attacker) if attacker else null
	)
	if animator:
		await animator.play_and_finish(animation_key())
	execute()


## Identifier passed to the actor's [PhaseAnimator]. Subclasses override
## to select per-move clips (e.g. [code]&"attack_overhead"[/code]).
func animation_key() -> StringName:
	return &"action"
