class_name TeamState extends Resource

## Observable state for one team across planning and defense.
##
## The model in an MVC sense. Holds the planning state machine
## ([member phase], [member active_character], [member selected_move],
## [member selected_targets]) and broadcasts a defense window during the
## opposing team's [AttackString]. Nodes mutate via the [code]select_*[/code]
## and [code]request_*[/code] methods; views subscribe to the signals.
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

## Emitted after [method commit_targets] packages a [CommittedAction] and
## appends it to [member committed_actions].
signal action_committed(action: CommittedAction)

## Emitted when [method go_back] rewinds one step in the planning state
## machine. Carries the phase the state returned to.
signal back_navigated(phase: Phase)

## Emitted when [member pending_characters] empties and [member phase]
## settles in [constant Phase.DONE]. Listeners can read
## [member committed_actions] for the result.
signal planning_finished

## Emitted by [method request_block] when the resolver needs the
## defender to react to [param beat] within [param window_sec] seconds.
signal defense_window_opened(beat: AttackBeat, window_sec: float)

## Emitted by [method request_parry] when the resolver needs the
## defender to parry a grab within [param window_sec] seconds.
signal parry_window_opened(window_sec: float)

## Emitted by [method complete_defense] with whatever the defending
## controller produced. Resolver awaits this to score the beat.
signal defense_window_closed(result: DefenseInput)

## Emitted by [AttackStringResolver] when an attacker telegraphs
## [param beat] against a character on this team. Mirrors the resolver's
## own signal so UI nodes can bind to the defender's [TeamState] without
## holding a reference to the transient resolver.
signal beat_telegraphed(beat: AttackBeat)

## Emitted after a beat resolves against a character on this team.
signal beat_resolved(beat: AttackBeat, blocked: bool, damage: int)

## Emitted after an [enum AttackString.Ender] resolves against a
## character on this team. [param ender] is the [enum AttackString.Ender]
## value.
signal ender_resolved(ender: int, hit: bool, damage: int)

## Current step of the planning state machine. Read-only to consumers -
## mutate via [method begin_planning], [method select_character], etc.
var phase: Phase = Phase.IDLE

## Characters that still need to plan this turn. Drained by
## [method commit_targets]; reset by [method begin_planning].
var pending_characters: Array[Character] = []

## Character currently being planned for. [code]null[/code] in
## [constant Phase.IDLE] / [constant Phase.DONE].
var active_character: Character = null

## Move chosen by the active character; set during
## [constant Phase.PICKING_TARGETS], cleared on commit or back-nav.
var selected_move: CombatAction = null

## Targets accumulated during [constant Phase.PICKING_TARGETS]. Frozen
## into a [CommittedAction] by [method commit_targets].
var selected_targets: Array[Character] = []

## Actions committed by this team this turn, in commit order. Drained
## by [TeamManager] at end of planning.
var committed_actions: Array[CommittedAction] = []


## Resets state and starts a new planning sequence for [param roster].
##
## Pushes [member phase] to [constant Phase.PICKING_CHARACTER] (or
## [constant Phase.DONE] when the roster is empty) and emits
## [signal phase_changed].
func begin_planning(roster: Array[Character]) -> void:
	committed_actions = []
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
	_set_phase(Phase.PICKING_TARGETS)


## Freezes [param targets] into a [CommittedAction], removes the active
## character from [member pending_characters], and advances to either
## the next character or [constant Phase.DONE].
func commit_targets(targets: Array[Character]) -> void:
	if phase != Phase.PICKING_TARGETS:
		push_warning("TeamState.commit_targets called outside PICKING_TARGETS.")
		return
	if active_character == null or selected_move == null:
		push_warning("TeamState.commit_targets without an active char/move.")
		return
	selected_targets = targets.duplicate()
	targets_committed.emit(selected_targets)
	var action := CommittedAction.new(
		active_character, selected_move, selected_targets
	)
	committed_actions.append(action)
	action_committed.emit(action)
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


## Asks the bound defender controller for a block input against
## [param beat]. Emits [signal defense_window_opened]; the controller
## must respond with [method complete_defense] within
## [param window_sec].
func request_block(beat: AttackBeat, window_sec: float) -> void:
	defense_window_opened.emit(beat, window_sec)


## Asks the bound defender controller for a parry input. Emits
## [signal parry_window_opened]; the controller must respond with
## [method complete_defense] within [param window_sec].
func request_parry(window_sec: float) -> void:
	parry_window_opened.emit(window_sec)


## Reports the defender's reaction back to the resolver. Emitted as
## [signal defense_window_closed]. Pass [method DefenseInput.none] for
## a timeout/no-react.
func complete_defense(result: DefenseInput) -> void:
	defense_window_closed.emit(result)


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
