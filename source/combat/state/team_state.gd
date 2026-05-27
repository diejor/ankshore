class_name TeamState extends Resource

## Observable state for one team's planning flow.
##
## The model in an MVC sense. Holds the planning state machine
## ([member phase], [member active_character], [member selected_move],
## [member selected_targets]). Nodes mutate via the [code]select_*[/code]
## methods; views subscribe to the signals.
##
## [br][br]
## One instance per team per encounter. Constructed by [TeamManager] -
## not authored as a [code].tres[/code] - so the [Character] refs it
## holds are scene-scoped and never serialized.

## Steps of the planning state machine. [constant Phase.IDLE] is the
## resting state when this team is neither planning nor defending.
## [br]- [code]IDLE[/code]: not planning.
## [br]- [code]PICKING_CHARACTER[/code]: waiting for [method select_character].
## [br]- [code]PICKING_MOVE[/code]: waiting for [method select_move].
## [br]- [code]PICKING_TARGETS[/code]: waiting for [method commit_targets].
## [br]- [code]DONE[/code]: planning finished for this turn.
enum Phase {
	IDLE,
	PICKING_CHARACTER,
	PICKING_MOVE,
	PICKING_TARGETS,
	DONE,
}

## Emitted when [member phase] transitions. Carries the new phase value.
signal phase_changed(phase: Phase)

## Emitted when [member active_character] is reassigned, including the
## transition from non-null to null at end-of-planning.
signal active_character_changed(character: Character)

## Emitted when [method select_move] commits a move for the active
## character. Carries the chosen move.
signal move_selected(move: CombatAction)

## Emitted when [method commit_targets] commits targets for the selected
## move. Carries the final target list.
signal targets_committed(targets: Array[Character])

## Emitted after [method commit_targets] stores a pending move on
## [param character].
signal action_committed(character: Character)

## Emitted when [method go_back] rewinds one step in the planning state
## machine. Carries the phase the state returned to.
signal back_navigated(phase: Phase)

## Emitted when [member pending_characters] empties and [member phase]
## settles in [constant Phase.DONE]. Listeners can read
## the characters' pending moves for the result.
signal planning_finished

## Current step of the planning state machine. Read-only to consumers -
## mutate via [method begin_planning], [method select_character], etc.
var phase: Phase = Phase.IDLE

## Characters that still need to plan this turn. Drained by
## [method commit_targets]; reset by [method begin_planning].
var pending_characters: Array[Character] = []

## Character currently being planned for. [code]null[/code] in
## [constant Phase.IDLE] / [constant Phase.DONE].
var active_character: Character = null

## Move chosen by the active character. Cleared on commit or back-nav.
var selected_move: CombatAction = null

## Targets accumulated during [constant Phase.PICKING_TARGETS].
var selected_targets: Array[Character] = []


## Resets state and starts a new planning sequence for [param roster].
##
## Pushes [member phase] to [constant Phase.PICKING_CHARACTER] (or
## [constant Phase.DONE] when the roster is empty) and emits
## [signal phase_changed].
func begin_planning(roster: Array[Character]) -> void:
	pending_characters = roster.duplicate()
	selected_move = null
	selected_targets = []
	_set_active(null)
	if pending_characters.is_empty():
		_set_phase(Phase.DONE)
		planning_finished.emit()
		return
	_set_phase(Phase.PICKING_CHARACTER)


## Commits [param character] as the actor being planned for. Must be
## one of [member pending_characters]; pushes [member phase] to
## [constant Phase.PICKING_MOVE].
func select_character(character: Character) -> void:
	if phase != Phase.PICKING_CHARACTER:
		push_warning("TeamState.select_character called outside PICKING_CHARACTER.")
		return
	if not pending_characters.has(character):
		push_warning("TeamState.select_character: character not pending.")
		return
	_set_active(character)
	_set_phase(Phase.PICKING_MOVE)


## Commits [param move] as the active character's chosen move and
## advances to [constant Phase.PICKING_TARGETS].
func select_move(move: CombatAction) -> void:
	if phase != Phase.PICKING_MOVE:
		push_warning("TeamState.select_move called outside PICKING_MOVE.")
		return
	selected_move = move
	move_selected.emit(move)
	if selected_move and selected_move.targets_self:
		selected_targets = [active_character]
		_commit_selected_action()
		return
	_set_phase(Phase.PICKING_TARGETS)


## Stores [param targets] and the selected move on the active character,
## then advances to the next character or [constant Phase.DONE].
func commit_targets(targets: Array[Character]) -> void:
	if phase != Phase.PICKING_TARGETS:
		push_warning("TeamState.commit_targets called outside PICKING_TARGETS.")
		return
	if active_character == null or selected_move == null:
		push_warning("TeamState.commit_targets without an active char/move.")
		return
	selected_targets = targets.duplicate()
	_commit_selected_action()


# Commits the selected action, then advances to the next planner.
func _commit_selected_action() -> void:
	targets_committed.emit(selected_targets)
	active_character.commit_move(selected_move, selected_targets)
	action_committed.emit(active_character)
	pending_characters.erase(active_character)
	selected_move = null
	selected_targets = []
	_set_active(null)
	if pending_characters.is_empty():
		_set_phase(Phase.DONE)
		planning_finished.emit()
	else:
		_set_phase(Phase.PICKING_CHARACTER)


## Rewinds one step. [constant Phase.PICKING_TARGETS] returns to
## [constant Phase.PICKING_MOVE]; [constant Phase.PICKING_MOVE] returns
## to [constant Phase.PICKING_CHARACTER]; other phases are no-ops.
func go_back() -> void:
	match phase:
		Phase.PICKING_TARGETS:
			selected_move = null
			selected_targets = []
			_set_phase(Phase.PICKING_MOVE)
			back_navigated.emit(phase)
		Phase.PICKING_MOVE:
			_set_active(null)
			_set_phase(Phase.PICKING_CHARACTER)
			back_navigated.emit(phase)


# Internal phase setter. Centralizes the change signal.
func _set_phase(new_phase: Phase) -> void:
	if new_phase == phase:
		return
	phase = new_phase
	phase_changed.emit(phase)


# Internal active-character setter. Centralizes the change signal.
func _set_active(c: Character) -> void:
	if c == active_character:
		return
	active_character = c
	active_character_changed.emit(c)
