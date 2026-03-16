class_name turnManager extends Node

signal turnEnded(team: Team)
signal turnStart(team: Team)
signal matchStart(team: Team)

enum Team {
	Ally,
	Enemy
}

var current_team: Team = Team.Ally

@onready var turn_label: DebugLabel = %TurnLabel
@onready var turn_timer: Timer = %TurnTimer
@onready var turn_timer_label: DebugLabel = %TurnTimerLabel

func _ready() -> void:
	update_turn_label()
	matchStart.emit(current_team)
	turnStart.emit(current_team)

func update_turn_label() -> void:
	var team_string: String
	
	if current_team == Team.Ally:
		team_string = "Ally"
	elif current_team == Team.Enemy:
		team_string = "Enemy"
	
	turn_label.text = "Turn: %s" % team_string

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_turn"):
		next_turn()
		update_turn_label()


func update_timer_label() -> void:
	turn_timer_label.text = "Time Left: %ss" % str(int(turn_timer.time_left))


func next_turn() -> void:
	turnEnded.emit(current_team)
	
	if current_team == Team.Ally:
		current_team = Team.Enemy
	elif current_team == Team.Enemy:
		current_team = Team.Ally
	
	turnStart.emit(current_team)
	update_turn_label()


func _on_seconds_beat() -> void:
	update_timer_label()


func _on_turn_start(_team: turnManager.Team) -> void:
	turn_timer.start()


func _on_turn_timer_timeout() -> void:
	next_turn()
