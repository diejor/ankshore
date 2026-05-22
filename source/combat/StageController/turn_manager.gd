class_name TurnManager extends Node

## Controls turn order and progression for a combat encounter.
##
## [br][br]
## Call [method end_turn] to conclude the active turn from any
## source - a timer timeout, player input, or team logic.
## The sequence advances to the next team and emits
## [signal turn_started].

signal turn_started(team: TeamManager)
signal turn_ended(team: TeamManager)
signal match_started(team: TeamManager)

## The team whose turn is currently active.
@export var current_team: TeamManager
## All participating teams in turn order.
@export var teams: Array[TeamManager]

@export var current_turn: int = 0

var _is_turn_active: bool = false


func _ready() -> void:
	_connect_teams()
	match_started.emit(current_team)
	# Defer the first turn to ensure all ready handlers have run.
	_start_turn.call_deferred(current_team)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_turn"):
		end_turn()


## Concludes the active turn and advances to the next team.
##
## [br][br]
## Safe to call from a timer timeout, player input, or team
## logic. Has no effect when no turn is in progress.
func end_turn() -> void:
	if not _is_turn_active:
		push_warning("`end_turn` called when no turn is active.")
		return
	
	_is_turn_active = false
	turn_ended.emit(current_team)
	
	var idx := teams.find(current_team)
	if idx == -1:
		push_error("Current team not found in teams array.")
		return
	
	var next_team := teams[(idx + 1) % teams.size()]
	current_turn += 1
	_start_turn(next_team)


## Returns the opponent of [param team].
func get_other_team(team: TeamManager) -> TeamManager:
	for other in teams:
		if other != team:
			return other
	return null


# Wires [signal turn_started] to all registered teams.
func _connect_teams() -> void:
	for team in teams:
		if not turn_started.is_connected(team._on_turn_started):
			turn_started.connect(team._on_turn_started)


# Begins a new turn for the designated team and manages turn state.
func _start_turn(team: TeamManager) -> void:
	current_team = team
	_is_turn_active = true
	turn_started.emit(current_team)
