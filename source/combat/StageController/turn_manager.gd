class_name turnManager extends Node

signal turnEnded(team: TeamManager.Team)
signal turnStart(team: TeamManager.Team)
signal matchStart(team: TeamManager.Team)



var current_team: TeamManager.Team = TeamManager.Team.Ally:
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
	
	if current_team == TeamManager.Team.Ally:
		current_team = TeamManager.Team.Enemy
	elif current_team == TeamManager.Team.Enemy:
		current_team = TeamManager.Team.Ally
	
	turnStart.emit(current_team)


func _on_turn_timer_timeout() -> void:
	next_turn()
