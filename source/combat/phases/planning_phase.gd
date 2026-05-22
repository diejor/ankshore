class_name PlanningPhase extends RefCounted

## Both teams plan their actions before any of them resolve.
##
## [br][br]
## Loops through the pending characters of attacker-then-defender teams,
## letting the user pick a character via [CharacterSelectionStep] and
## then a move + targets via [MoveSelectionStep]. The collected
## [CommittedAction]s are returned to the [TurnManager] for handoff to
## [ResolutionPhase].
##
## [br][br]
## Runs to completion: every pending character gets their turn at the
## picker. Back-navigation lives one level down, inside the per-character
## steps - the phase itself is not interruptible.

signal phase_started
signal phase_finished
signal active_character_changed(character: Character)
signal character_plan_changed(character: Character, summary: Dictionary)


## Returns the actions committed by every pending character on both
## teams. The array is in commit order; [ResolutionPhase] sorts it.
func run(ctx: PhaseContext) -> Array[CommittedAction]:
	phase_started.emit()

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"planning_in")

	var pending: Array[Character] = _initial_pending(ctx)
	var committed: Array[CommittedAction] = []

	while not pending.is_empty():
		var char_step := CharacterSelectionStep.new(pending)
		var character: Character = await char_step.run()
		if character == null:
			continue

		active_character_changed.emit(character)

		var move_step := MoveSelectionStep.new(character)
		move_step.summary_changed.connect(
			func(s: Dictionary) -> void:
				character_plan_changed.emit(character, s)
		)
		var action: CommittedAction = await move_step.run(ctx)
		if action == null:
			continue

		committed.append(action)
		pending.erase(character)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"planning_out")

	phase_finished.emit()
	return committed


func _initial_pending(ctx: PhaseContext) -> Array[Character]:
	var pending: Array[Character] = []
	var attacker := ctx.turn_manager.attacker_team
	if attacker:
		for c in attacker.pending_characters():
			pending.append(c)
	for team in ctx.turn_manager.teams:
		if team == attacker:
			continue
		for c in team.pending_characters():
			pending.append(c)
	return pending
