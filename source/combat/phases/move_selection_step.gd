class_name MoveSelectionStep extends RefCounted

## Picks a move for [member actor] and drills into target selection.
##
## [br][br]
## Loops until the user either commits a full action (move + targets)
## or backs out at the move list. Returns the committed action or
## [code]null[/code] - the parent treats null as "re-pick character".

signal summary_changed(summary: Dictionary)

var actor: Character
var _selected_move: CombatAction


func _init(p_actor: Character) -> void:
	actor = p_actor


## Returns a [CommittedAction] on success, or [code]null[/code] when
## the user backed out at the move list.
func run(ctx: PhaseContext) -> CommittedAction:
	var ui := ctx.move_list_ui
	if ui == null:
		push_error("MoveSelectionStep requires ctx.move_list_ui.")
		return null

	while true:
		ui.present(actor)
		var pick: CombatAction = await _await_move_pick(ui)
		ui.dismiss()
		if pick == null:
			return null

		_selected_move = pick
		summary_changed.emit(summary())

		var target_step := TargetSelectionStep.new(actor, _selected_move)
		var targets: Array[Character] = await target_step.run()
		if targets.is_empty():
			continue

		return CommittedAction.new(actor, _selected_move, targets)

	return null


func summary() -> Dictionary:
	return {
		"actor": actor,
		"move": _selected_move,
	}


func _await_move_pick(ui: MoveListUI) -> CombatAction:
	var gate := _MoveGate.new()
	ui.move_picked.connect(gate.on_picked)
	ui.cancelled.connect(gate.on_cancelled)

	await gate.resolved

	if ui.move_picked.is_connected(gate.on_picked):
		ui.move_picked.disconnect(gate.on_picked)
	if ui.cancelled.is_connected(gate.on_cancelled):
		ui.cancelled.disconnect(gate.on_cancelled)

	return gate.value


class _MoveGate extends RefCounted:
	signal resolved
	var value: CombatAction = null
	var _done: bool = false

	func on_picked(action: CombatAction) -> void:
		if _done:
			return
		_done = true
		value = action
		resolved.emit()

	func on_cancelled() -> void:
		if _done:
			return
		_done = true
		resolved.emit()
