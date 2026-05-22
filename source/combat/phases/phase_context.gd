class_name PhaseContext extends RefCounted

## Shared services threaded through every planning step and phase.
##
## Steps never reach into the scene tree directly. They request an
## animator role via [method animator_for] and read [member turn_manager]
## from this bundle.

var turn_manager: TurnManager
var ui_animator: PhaseAnimator
var camera_animator: PhaseAnimator
var character_animators: Dictionary = {}


## Returns the [PhaseAnimator] registered for [param character], or
## [code]null[/code] if none was provided.
func animator_for(character: Character) -> PhaseAnimator:
	return character_animators.get(character)
