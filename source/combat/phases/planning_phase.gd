class_name PlanningPhase extends RefCounted

## Both teams plan their actions before any of them resolve.
##
## Iterates the teams in attacker-first order, calling
## [method TeamManager.run_planning] on each. The phase itself stays
## dumb - all decision logic lives on the team's bound controller
## ([PlayerController], [AIController], ...) driving its [TeamState].

## Runs each team's planning sequence in attacker-first order and
## returns the combined character list. [ResolutionPhase] sorts by speed.
func run(_ctx: PhaseContext, turn_manager: TurnManager) -> Array[Character]:
	var all_characters: Array[Character] = []
	for team in _teams_in_order(turn_manager):
		turn_manager.planning_team_started.emit(team)
		var characters: Array[Character] = await team.run_planning()
		turn_manager.planning_team_finished.emit(team, characters)
		all_characters.append_array(characters)

	return all_characters


# Attacker team plans first, then the rest in declaration order.
func _teams_in_order(turn_manager: TurnManager) -> Array[TeamManager]:
	var ordered: Array[TeamManager] = []
	var attacker := turn_manager.attacker_team
	if attacker:
		ordered.append(attacker)
	for t in turn_manager.teams:
		if t != attacker:
			ordered.append(t)
	return ordered
