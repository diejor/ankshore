class_name turnManager extends Node
@warning_ignore("unused_signal")
signal turnEnded(team: Teams)
@warning_ignore("unused_signal")
signal turnStart(team: Teams)
@warning_ignore("unused_signal")
signal matchStart(team: Teams)

enum Teams {
	Ally,
	Enemy
}

var current_team: Teams = Teams.Ally

@onready var turn_label: DebugLabel = %TurnLabel
@onready var turn_timer: Timer = %TurnTimer
@onready var turn_timer_label: DebugLabel = %TurnTimerLabel

func _ready() -> void:
	update_turn_label()
	matchStart.emit(current_team)
	turnStart.emit(current_team)

func update_turn_label() -> void:
	var team_string: String
	
	if current_team == Teams.Ally:
		team_string = "Ally"
	elif current_team == Teams.Enemy:
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
	
	if current_team == Teams.Ally:
		current_team = Teams.Enemy
	elif current_team == Teams.Enemy:
		current_team = Teams.Ally
	
	turnStart.emit(current_team)
	update_turn_label()


func _on_seconds_beat() -> void:
	update_timer_label()


func _on_turn_start(_team: turnManager.Teams) -> void:
	turn_timer.start()


func _on_turn_timer_timeout() -> void:
	next_turn()
