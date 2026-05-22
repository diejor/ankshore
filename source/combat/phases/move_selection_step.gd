class_name MoveSelectionStep extends RefCounted

## Picks a move for [member actor] and drills into target selection.
##
## Loops until the user either commits a full action (move + targets)
## or backs out at the move list. Returns the committed action or
## [code]null[/code] - the parent treats null as "re-pick character".

signal summary_changed(summary: Dictionary)

var _controller: TeamController
var actor: Character
var _selected_move: CombatAction


func _init(controller: TeamController, p_actor: Character) -> void:
	_controller = controller
	actor = p_actor


## Returns a [CommittedAction] on success, or [code]null[/code] when
## the user backed out at the move list.
func run() -> CommittedAction:
	while true:
		_present_move_list()
		var pick: CombatAction = await _await_move_pick()
		_dismiss_move_list()
		if pick == null:
			return null

		_selected_move = pick
		summary_changed.emit(summary())

		var target_step := TargetSelectionStep.new(
			_controller, actor, _selected_move
		)
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


func _present_move_list() -> void:
	if _controller is LocalController:
		(_controller as LocalController).present_move_list(actor)


func _dismiss_move_list() -> void:
	if _controller is LocalController:
		(_controller as LocalController).dismiss_move_list()


func _await_move_pick() -> CombatAction:
	var gate := _Gate.new()
	_controller.move_picked.connect(gate.on_picked)
	_controller.back_requested.connect(gate.on_back)

	await gate.resolved

	if _controller.move_picked.is_connected(gate.on_picked):
		_controller.move_picked.disconnect(gate.on_picked)
	if _controller.back_requested.is_connected(gate.on_back):
		_controller.back_requested.disconnect(gate.on_back)

	return gate.value


class _Gate extends RefCounted:
	signal resolved
	var value: CombatAction = null
	var _done: bool = false

	func on_picked(action: CombatAction) -> void:
		if _done:
			return
		_done = true
		value = action
		resolved.emit()

	func on_back() -> void:
		if _done:
			return
		_done = true
		resolved.emit()
