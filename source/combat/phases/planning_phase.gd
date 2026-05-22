class_name PlanningPhase extends RefCounted

## Both teams plan their actions before any of them resolve.
##
## Iterates the teams in attacker-first order, calling
## [method TeamManager.run_planning] on each. The phase itself stays
## dumb - all decision logic lives on the team's bound controller
## ([PlayerController], [AIController], ...) driving its [TeamState].

## Emitted when the phase begins.
signal phase_started

## Emitted when both teams finish planning.
signal phase_finished

## Emitted before [param team] starts planning.
signal team_started(team: TeamManager)

## Emitted with the actions [param team] committed during its planning
## sequence.
signal team_finished(team: TeamManager, actions: Array[CommittedAction])


## Runs each team's planning sequence in attacker-first order and
## returns the combined action list. [ResolutionPhase] sorts by speed.
func run(ctx: PhaseContext) -> Array[CommittedAction]:
	phase_started.emit()

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"planning_in")

	var all_actions: Array[CommittedAction] = []
	for team in _teams_in_order(ctx):
		team_started.emit(team)
		var actions: Array[CommittedAction] = await team.run_planning()
		team_finished.emit(team, actions)
		all_actions.append_array(actions)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"planning_out")

	phase_finished.emit()
	return all_actions


# Attacker team plans first, then the rest in declaration order.
func _teams_in_order(ctx: PhaseContext) -> Array[TeamManager]:
	var ordered: Array[TeamManager] = []
	var attacker := ctx.turn_manager.attacker_team
	if attacker:
		ordered.append(attacker)
	for t in ctx.turn_manager.teams:
		if t != attacker:
			ordered.append(t)
	return ordered
