class_name TurnManager extends Node

signal turn_ended(team: TeamManager)
signal turn_start(team: TeamManager)
signal match_start(team: TeamManager)

var current_turn: int = 0

@export var current_team: TeamManager
@export var teams: Array[TeamManager]

var _turn_mutex := AsyncMutex.new()

func _init() -> void:
	turn_start.connect(_on_turn_start)
	turn_ended.connect(_on_turn_ended)

func _ready() -> void:
	_ensure_teams_connected()
	match_start.emit(current_team)
	turn_start.emit.call_deferred(current_team)

func _ensure_teams_connected() -> void:
	for team in teams:
		if not turn_start.is_connected(team._on_turn_start):
			turn_start.connect(team._on_turn_start)
		if not turn_ended.is_connected(team._on_turn_ended):
			turn_ended.connect(team._on_turn_ended)

func _on_turn_start(_team: TeamManager) -> void:
	if _turn_mutex.is_locked():
		push_warning("`turn_start` signal fired during a turn.")
		return
	
	_turn_mutex.lock()

func _on_turn_ended(_team: TeamManager) -> void:
	_turn_mutex.unlock()
	next_turn()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_turn"):
		next_turn()

func get_other_team(team: TeamManager) -> TeamManager:
	for ateam in teams:
		if ateam == team:
			continue
		return ateam
	return null

func next_turn() -> void:
	if _turn_mutex.is_locked():
		push_warning("`next_turn` cannot be called if a turn is happening.")
		return
	
	var current_team_idx: int = teams.find(current_team)
	var next_team_idx: int = (current_team_idx + 1) % teams.size()
	current_team = teams[next_team_idx]
	current_turn += 1
	
	turn_start.emit(current_team)


func _on_turn_timer_timeout() -> void:
	turn_ended.emit(current_team)
