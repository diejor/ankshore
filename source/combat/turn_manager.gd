class_name turnManager extends Node

signal turnEnded(team: Team)
signal turnStart(team: Team)
signal matchStart(team: Team)

enum Team {
	Ally,
	Enemy
}


var current_team: Team = Team.Ally:
	set(team):
		current_team = team


func _ready() -> void:
	matchStart.emit(current_team)
	turnStart.emit(current_team)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_turn"):
		next_turn()


func next_turn() -> void:
	turnEnded.emit(current_team)
	
	if current_team == Team.Ally:
		current_team = Team.Enemy
	elif current_team == Team.Enemy:
		current_team = Team.Ally
	
	turnStart.emit(current_team)


func _on_turn_timer_timeout() -> void:
	next_turn()
