class_name TeamState extends Resource

## Observable state for one team's planning flow.
##
## The model in an MVC sense. Holds the planning state machine
## ([member phase], [member active_character], [member selected_move],
## [member selected_target]). Nodes mutate via the [code]select_*[/code]
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
## [br]- [code]PICKING_TARGETS[/code]: waiting for [method commit_target].
## [br]- [code]BUILDING_STRING[/code]: attacker assembling beats before an
##   attack move commits via [method commit_string].
## [br]- [code]DONE[/code]: planning finished for this turn.
enum Phase {
	IDLE,
	PICKING_CHARACTER,
	PICKING_MOVE,
	PICKING_TARGETS,
	BUILDING_STRING,
	DONE,
}

## Emitted when [member phase] transitions. Carries the new phase value.
signal phase_changed(phase: Phase)

## Emitted when [member active_character] is reassigned, including the
## transition from non-null to null at end-of-planning.
signal active_character_changed(character: Character)

## Emitted when [method select_move] commits a move for the active
## character. Carries the chosen move.
signal move_selected(move: CharacterAction)

## Emitted when [method commit_target] commits target for the selected
## move. Carries the final target.
signal target_committed(target: Character)

## Emitted after [method commit_target] stores a pending move on
## [param character].
signal action_committed(character: Character)

## Emitted when [method commit_target] selects an attack move, handing
## off to the interactive string-building step. Carries the chosen move
## and committed target.
signal string_building_started(
	move: CombatAction, target: Character
)

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
## [method commit_target]; reset by [method begin_planning].
var pending_characters: Array[Character] = []

## Character currently being planned for. [code]null[/code] in
## [constant Phase.IDLE] / [constant Phase.DONE].
var active_character: Character = null

## Move chosen by the active character. Cleared on commit or back-nav.
var selected_move: CharacterAction = null

## Target accumulated during [constant Phase.PICKING_TARGETS].
var selected_target: Character = null


## Resets state and starts a new planning sequence for [param roster].
##
## Pushes [member phase] to [constant Phase.PICKING_CHARACTER] (or
## [constant Phase.DONE] when the roster is empty) and emits
## [signal phase_changed].
func begin_planning(roster: Array[Character]) -> void:
	pending_characters = roster.duplicate()
	selected_move = null
	selected_target = null
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
func select_move(move: CharacterAction) -> void:
	if phase != Phase.PICKING_MOVE:
		push_warning("TeamState.select_move called outside PICKING_MOVE.")
		return
	selected_move = move
	move_selected.emit(move)
	if selected_move and selected_move.targets_self:
		selected_target = active_character
		target_committed.emit(selected_target)
		active_character.commit_action(selected_move, selected_target)
		_advance_after_commit()
		return
	_set_phase(Phase.PICKING_TARGETS)


## Stores [param target] for the selected move. A [CombatAction] advances
## to [constant Phase.BUILDING_STRING]; any other action commits directly
## and advances to the next character or [constant Phase.DONE].
func commit_target(target: Character) -> void:
	if phase != Phase.PICKING_TARGETS:
		push_warning("TeamState.commit_target called outside PICKING_TARGETS.")
		return
	if active_character == null or selected_move == null:
		push_warning("TeamState.commit_target without an active char/move.")
		return
	selected_target = target
	target_committed.emit(selected_target)
	if selected_move is CombatAction:
		_set_phase(Phase.BUILDING_STRING)
		string_building_started.emit(selected_move, selected_target)
		return
	active_character.commit_action(selected_move, selected_target)
	_advance_after_commit()


## Seals an [AttackString] from [param beats], stores it on the active
## character's [CombatAction], then advances. Called by the attacker's
## controller to close [constant Phase.BUILDING_STRING].
func commit_string(beats: Array[AttackBeat]) -> void:
	if phase != Phase.BUILDING_STRING:
		push_warning("TeamState.commit_string called outside BUILDING_STRING.")
		return
	if active_character == null or selected_move == null:
		push_warning("TeamState.commit_string without an active char/move.")
		return
	var attack := AttackString.new()
	attack.beats = beats.duplicate()
	active_character.commit_action(selected_move, selected_target, attack)
	_advance_after_commit()


# Records the commit and advances to the next planner.
func _advance_after_commit() -> void:
	action_committed.emit(active_character)
	pending_characters.erase(active_character)
	selected_move = null
	selected_target = null
	_set_active(null)
	if pending_characters.is_empty():
		_set_phase(Phase.DONE)
		planning_finished.emit()
	else:
		_set_phase(Phase.PICKING_CHARACTER)


## Rewinds one step. [constant Phase.BUILDING_STRING] returns to
## [constant Phase.PICKING_TARGETS]; [constant Phase.PICKING_TARGETS]
## returns to [constant Phase.PICKING_MOVE]; [constant Phase.PICKING_MOVE]
## returns to [constant Phase.PICKING_CHARACTER]; other phases are no-ops.
func go_back() -> void:
	match phase:
		Phase.BUILDING_STRING:
			_set_phase(Phase.PICKING_TARGETS)
			back_navigated.emit(phase)
		Phase.PICKING_TARGETS:
			selected_move = null
			selected_target = null
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
