class_name CharacterSelectionStep extends RefCounted

## Awaits the user picking one of the [param pending] characters.
##
## [br][br]
## Toggles each pending character's slot into [code]SELECTABLE_OWN[/code],
## grabs focus on the first (or the previously-focused one when
## re-entered), and returns the chosen [Character] when a slot fires
## [signal SelectionSlot.user_selected].

var _pending: Array[Character]
var _last_focused: Character


func _init(pending: Array[Character]) -> void:
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
	if initial:
		initial.grab_focus.call_deferred()

	var picked_slot: SelectionSlot = await _await_any_selection(slots)

	for slot in slots:
		slot.set_step_mode(SelectionSlot.StepMode.INERT)

	if picked_slot == null:
		return null
	var chosen := picked_slot.get_character()
	_last_focused = chosen
	return chosen


func _collect_slots() -> Array[SelectionSlot]:
	var slots: Array[SelectionSlot] = []
	for character in _pending:
		var slot := character.get_parent() as SelectionSlot
		if slot:
			slots.append(slot)
	return slots


func _resolve_initial_slot(slots: Array[SelectionSlot]) -> SelectionSlot:
	if _last_focused:
		for slot in slots:
			if slot.get_character() == _last_focused:
				return slot
	return slots[0] if not slots.is_empty() else null


func _await_any_selection(
	slots: Array[SelectionSlot]
) -> SelectionSlot:
	var gate := _SelectionGate.new()
	for slot in slots:
		slot.user_selected.connect(gate.on_selected)

	await gate.resolved

	for slot in slots:
		if slot.user_selected.is_connected(gate.on_selected):
			slot.user_selected.disconnect(gate.on_selected)

	return gate.value


class _SelectionGate extends RefCounted:
	signal resolved
	var value: SelectionSlot = null
	var _done: bool = false

	func on_selected(slot: SelectionSlot) -> void:
		if _done:
			return
		_done = true
		value = slot
		resolved.emit()
