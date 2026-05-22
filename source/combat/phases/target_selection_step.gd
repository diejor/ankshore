class_name TargetSelectionStep extends RefCounted

## Picks one or more enemy characters as targets for [member move].
##
## Toggles opposing slots into [code]SELECTABLE_TARGET[/code] and listens
## to the controller for [signal TeamController.slot_picked] and
## [signal TeamController.back_requested]. Returns the chosen targets,
## or an empty array on back-nav.
##
## v1 commits a single target on confirm; multi-target rules will move
## here when moves gain target-count metadata.

signal summary_changed(summary: Dictionary)

var _controller: TeamController
var actor: Character
var move: CombatAction
var _picked: Array[Character] = []
var _last_focused_slot: SelectionSlot


func _init(
	controller: TeamController,
	p_actor: Character,
	p_move: CombatAction
) -> void:
	_controller = controller
	actor = p_actor
	move = p_move


## Returns the chosen targets, or an empty array when the user backed
## out (the parent should re-prompt for a move).
func run() -> Array[Character]:
	var enemy_team := actor.team_manager.get_other_team()
	if enemy_team == null:
		return []

	var slots: Array[SelectionSlot] = []
	for slot in enemy_team.slots:
		if slot.get_character() and slot.get_character().is_alive():
			slot.set_step_mode(SelectionSlot.StepMode.SELECTABLE_TARGET)
			slots.append(slot)

	var initial := _last_focused_slot if _last_focused_slot else (
		slots[0] if not slots.is_empty() else null
	)
	if initial and _controller is LocalController:
		(_controller as LocalController).focus_on(initial)

	var result: Array[Character] = await _gather_picks(slots)

	for slot in slots:
		slot.set_step_mode(SelectionSlot.StepMode.INERT)

	return result


func summary() -> Dictionary:
	return {
		"actor": actor,
		"move": move,
		"targets": _picked.duplicate(),
	}


func _gather_picks(slots: Array[SelectionSlot]) -> Array[Character]:
	var gate := _Gate.new(slots)
	_controller.slot_picked.connect(gate.on_picked)
	_controller.back_requested.connect(gate.on_back)

	var result: Array[Character] = []
	while true:
		await gate.tick
		if gate.cancelled:
			break
		if gate.picked_slot:
			_last_focused_slot = gate.picked_slot
			var character := gate.picked_slot.get_character()
			if character and character.is_alive():
				result.append(character)
				_picked = result.duplicate()
				summary_changed.emit(summary())
				break
			gate.picked_slot = null

	if _controller.slot_picked.is_connected(gate.on_picked):
		_controller.slot_picked.disconnect(gate.on_picked)
	if _controller.back_requested.is_connected(gate.on_back):
		_controller.back_requested.disconnect(gate.on_back)

	return result


class _Gate extends RefCounted:
	signal tick
	var picked_slot: SelectionSlot
	var cancelled: bool = false
	var _eligible: Array[SelectionSlot]

	func _init(eligible: Array[SelectionSlot]) -> void:
		_eligible = eligible

	func on_picked(slot: SelectionSlot) -> void:
		if not _eligible.has(slot):
			return
		picked_slot = slot
		tick.emit()

	func on_back() -> void:
		cancelled = true
		tick.emit()
