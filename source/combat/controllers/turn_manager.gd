class_name TurnManager extends Node

## Drives the planning/resolution loop of a combat encounter.
##
## Each turn nominates an [member attacker_team]. Both teams plan
## simultaneously via [PlanningPhase], then [ResolutionPhase] executes
## the collected actions in speed order. Back-navigation is a per-step
## concern inside the planning tree; this class is intentionally not
## an interrupt boundary.

signal turn_started(attacker: TeamManager)
signal turn_ended(attacker: TeamManager)
signal match_started(attacker: TeamManager)
signal match_ended
signal planning_finished

## Team holding the attacker role this turn.
@export var attacker_team: TeamManager

## All participating teams in attacker-rotation order.
@export var teams: Array[TeamManager]

## One controller per team. Defines who plans each team's turn
## (local input, AI, network). Order is independent of [member teams];
## controllers are paired to teams by [member TeamController.team].
@export var controllers: Array[TeamController] = []

@export var current_turn: int = 0

var _running: bool = false


## Runs the full match loop until [method _is_match_over] returns true.
## Call once from the scene bootstrap.
func run_match(ctx: PhaseContext) -> void:
	if _running:
		push_error("TurnManager.run_match called while already running.")
		return
	_running = true
	match_started.emit(attacker_team)

	while not _is_match_over():
		turn_started.emit(attacker_team)

		var planning := PlanningPhase.new()
		var actions: Array[CommittedAction] = await planning.run(ctx)
		planning_finished.emit()

		var resolution := ResolutionPhase.new(actions)
		await resolution.run(ctx)

		turn_ended.emit(attacker_team)
		_rotate_attacker()
		current_turn += 1

	_running = false
	match_ended.emit()


## Placeholder retained so the scene's [code]TurnTimer.timeout[/code]
## connection still resolves. No-op until per-step timeouts replace it.
func end_turn() -> void:
	pass


## Returns the opponent of [param team].
func get_other_team(team: TeamManager) -> TeamManager:
	for other in teams:
		if other != team:
			return other
	return null


func _rotate_attacker() -> void:
	var idx := teams.find(attacker_team)
	if idx == -1:
		push_error("attacker_team not found in teams array.")
		return
	attacker_team = teams[(idx + 1) % teams.size()]


func _is_match_over() -> bool:
	var alive_teams := 0
	for team in teams:
		for character in team.tracked_characters:
			if character and character.is_alive():
				alive_teams += 1
				break
	return alive_teams < 2
