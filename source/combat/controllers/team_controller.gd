@abstract class_name TeamController extends Node

## Scope through which a single team plans its turn.
##
## Implementations decide HOW plans are produced (local input, AI policy,
## network sync). They also own the input filter and the UI surface for
## their team - planning steps never reach for global input or singleton
## UI nodes, they subscribe to controller signals instead.

## Emitted when a focused [SelectionSlot] inside this controller's scope
## is committed by the user.
@warning_ignore("unused_signal")
signal slot_picked(slot: SelectionSlot)

## Emitted on [code]ui_cancel[/code] within this controller's scope.
## Steps interpret this as "back-nav out of the current sub-tree."
@warning_ignore("unused_signal")
signal back_requested

## Emitted when this controller's move list UI commits a move.
@warning_ignore("unused_signal")
signal move_picked(move: CombatAction)

signal activated
signal deactivated

## The team this controller plans for.
@export var team: TeamManager

var is_active: bool = false


## Plans this team's turn. Concrete controllers decide HOW ([LocalController]) 
## but agree on the return contract.
func plan_turn(_ctx: PhaseContext) -> Array[CommittedAction]:
	await get_tree().create_timer(0.001).timeout
	return []


## Brings this controller into focus. Pushes focus into its scope and
## starts accepting input.
func activate() -> void:
	if is_active:
		return
	is_active = true
	activated.emit()


## Steps the controller out of focus; remembers any state needed to
## restore on next [method activate].
func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	deactivated.emit()
