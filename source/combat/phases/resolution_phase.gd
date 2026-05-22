class_name ResolutionPhase extends RefCounted

## Executes the [CommittedAction]s collected by [PlanningPhase] in
## descending order of [member CommittedAction.speed_roll].
##
## Each action's [method CombatAction.execute_async] is awaited in turn
## so that per-character [AnimationTree] sequences play sequentially.
## Dead actors and actions whose targets are all dead are skipped. The
## phase plays out to completion - once planning commits, nothing
## interrupts it.

signal phase_started
signal phase_finished
signal action_started(action: CommittedAction)
signal action_finished(action: CommittedAction)

var _actions: Array[CommittedAction]


func _init(p_actions: Array[CommittedAction]) -> void:
	_actions = p_actions


func run(ctx: PhaseContext) -> void:
	phase_started.emit()

	_roll_speeds()
	_actions.sort_custom(
		func(a: CommittedAction, b: CommittedAction) -> bool:
			return a.speed_roll > b.speed_roll
	)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"resolution_in")

	for action in _actions:
		if not action.actor or not action.actor.is_alive():
			continue
		if not _has_live_target(action):
			continue
		action_started.emit(action)
		await action.to_runtime_action().execute_async(ctx)
		action_finished.emit(action)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"resolution_out")

	phase_finished.emit()


func _roll_speeds() -> void:
	for action in _actions:
		var base := (
			action.actor.stats.speed if action.actor and action.actor.stats
			else 0
		)
		action.speed_roll = base + randi_range(0, 9)


func _has_live_target(action: CommittedAction) -> bool:
	for target in action.targets:
		if target and target.is_alive():
			return true
	return false
