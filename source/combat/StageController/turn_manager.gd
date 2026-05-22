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

var current_turn: int = 0

#turn lock
var _turn_mutex := AsyncMutex.new()

# connects self-handlers so the mutex tracks every turn cycle
func _init() -> void:
	turn_started.connect(_on_turn_started)
	turn_ended.connect(_on_turn_ended)

# wires teams, announces match start, and defers the first turn
func _ready() -> void:
	_connect_teams()
	match_started.emit(current_team)
	turn_started.emit.call_deferred(current_team)

# manual shortcut - ends the current turn on input
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_turn"):
		end_turn()

## Concludes the active turn and advances to the next team.
##
## [br][br]
## Safe to call from a timer timeout, player input, or team
## logic. Has no effect when no turn is in progress.
func end_turn() -> void:
	if not _turn_mutex.is_locked():
		push_warning("`end_turn` called when no turn is active.")
		return
	turn_ended.emit(current_team)

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

# Advances [member current_team] and emits [signal turn_started].
func _next_turn() -> void:
	if _turn_mutex.is_locked():
		push_warning("`_next_turn` called while a turn is active.")
		return
	var idx: int = teams.find(current_team)
	current_team = teams[(idx + 1) % teams.size()]
	current_turn += 1
	turn_started.emit(current_team)

# locks the mutex so nothing else can advance the turn mid-action
func _on_turn_started(_team: TeamManager) -> void:
	if _turn_mutex.is_locked():
		push_warning("`turn_started` fired while a turn is active.")
		return
	_turn_mutex.lock()

# releases the lock then immediately sequences the next turn
func _on_turn_ended(_team: TeamManager) -> void:
	_turn_mutex.unlock()
	_next_turn()
