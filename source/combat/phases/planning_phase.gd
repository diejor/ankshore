class_name PlanningPhase extends RefCounted

## Both teams plan their actions before any of them resolve.
##
## Iterates [member TurnManager.controllers] in attacker-first order,
## activating each in turn and awaiting [method TeamController.plan_turn].
## The phase itself is dumb - all selection logic lives inside each
## controller. The collected [CommittedAction]s are returned to the
## [TurnManager] for handoff to [ResolutionPhase].

signal phase_started
signal phase_finished
signal controller_started(controller: TeamController)
signal controller_finished(
	controller: TeamController, actions: Array[CommittedAction]
)


## Returns the actions committed by every controller, in the order
## controllers planned. [ResolutionPhase] sorts by speed.
func run(ctx: PhaseContext) -> Array[CommittedAction]:
	phase_started.emit()

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"planning_in")

	var all_actions: Array[CommittedAction] = []
	for controller in _controllers_in_order(ctx):
		controller_started.emit(controller)
		controller.activate()
		var actions: Array[CommittedAction] = await controller.plan_turn(ctx)
		controller.deactivate()
		controller_finished.emit(controller, actions)
		all_actions.append_array(actions)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"planning_out")

	phase_finished.emit()
	return all_actions


func _controllers_in_order(ctx: PhaseContext) -> Array[TeamController]:
	var ordered: Array[TeamController] = []
	var attacker := ctx.turn_manager.attacker_team
	for controller in ctx.turn_manager.controllers:
		if controller.team == attacker:
			ordered.append(controller)
	for controller in ctx.turn_manager.controllers:
		if controller.team != attacker:
			ordered.append(controller)
	return ordered
