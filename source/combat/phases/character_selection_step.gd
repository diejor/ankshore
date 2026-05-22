class_name CharacterSelectionStep extends RefCounted

## Awaits the user picking one of the [param pending] characters.
##
## Toggles each pending character's slot into [code]SELECTABLE_OWN[/code]
## and asks the controller to focus the first (or the previously-focused
## one when re-entered). Returns when the controller fires
## [signal TeamController.slot_picked] with one of the eligible slots.

var _controller: TeamController
var _pending: Array[Character]
var _last_focused: Character


func _init(
	controller: TeamController,
	pending: Array[Character]
) -> void:
	_controller = controller
	_pending = pending


## Returns the picked [Character], or [code]null[/code] when there are
## no pending characters to choose from.
func run() -> Character:
	if _pending.is_empty():
		return null

	var slots := _collect_slots()
	for slot in slots:
		slot.set_step_mode(SelectionSlot.StepMode.SELECTABLE_OWN)

	var initial := _resolve_initial_slot(slots)
	if initial and _controller is LocalController:
		(_controller as LocalController).focus_on(initial)

	var gate := _Gate.new(slots)
	_controller.slot_picked.connect(gate.on_picked)
	await gate.resolved
	if _controller.slot_picked.is_connected(gate.on_picked):
		_controller.slot_picked.disconnect(gate.on_picked)

	for slot in slots:
		slot.set_step_mode(SelectionSlot.StepMode.INERT)

	if gate.value == null:
		return null
	var chosen := gate.value.get_character()
	_last_focused = chosen
	return chosen


func _collect_slots() -> Array[SelectionSlot]:
	var slots: Array[SelectionSlot] = []
	var team := _controller.team
	if team == null:
		return slots
	for slot in team.slots:
		if _pending.has(slot.get_character()):
			slots.append(slot)
	return slots


func _resolve_initial_slot(slots: Array[SelectionSlot]) -> SelectionSlot:
	if _last_focused:
		for slot in slots:
			if slot.get_character() == _last_focused:
				return slot
	return slots[0] if not slots.is_empty() else null


class _Gate extends RefCounted:
	signal resolved
	var value: SelectionSlot = null
	var _eligible: Array[SelectionSlot]
	var _done: bool = false

	func _init(eligible: Array[SelectionSlot]) -> void:
		_eligible = eligible

	func on_picked(slot: SelectionSlot) -> void:
		if _done or not _eligible.has(slot):
			return
		_done = true
		value = slot
		resolved.emit()
