class_name CombatAction extends Node

## Base class representing move data that can resolve during a turn.

## True when this action should commit against the actor itself without
## entering target selection.
@export var targets_self: bool = false


## Synchronous entry point. Subclasses apply gameplay effects here
## (damage, healing, buff application). Animation playback belongs in
## [method execute_async], not here.
func execute(_actor: Character, _targets: Array[Character]) -> void:
	pass


## Plays the actor's animation for this action and awaits its
## completion, then applies effects via [method execute]. Override to
## customise sequencing (e.g. apply damage on impact frame).
func execute_async(
	actor: Character,
	targets: Array[Character],
	ctx: PhaseContext
) -> void:
	var animator: PhaseAnimator = ctx.animator_for(actor) if actor else null
	if animator:
		await animator.play_and_finish(animation_key())
	execute(actor, targets)


## Identifier passed to the actor's [PhaseAnimator]. Subclasses override
## to select per-move clips (e.g. [code]&"attack_overhead"[/code]).
func animation_key() -> StringName:
	return &"action"
