class_name PhaseContext extends RefCounted

## Shared services threaded through every planning step and phase.
##
## Steps never reach into the scene tree directly. They read
## [member turn_manager] and [member inspection_state] from this bundle.

var turn_manager: TurnManager

## Shared inspection target read by panel UIs. Constructed once per
## encounter; UIs subscribe to [signal InspectionState.inspection_changed].
var inspection_state: InspectionState
