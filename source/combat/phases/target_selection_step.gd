class_name TargetSelectionStep extends RefCounted

## Picks one or more enemy characters as targets for [member move].
##
## [br][br]
## Toggles opposing slots into [code]SELECTABLE_TARGET[/code], grabs
## focus on the first valid one, and accumulates picks until the user
## confirms or backs out via [code]ui_cancel[/code].
##
## [br][br]
## v1 commits a single target on confirm; multi-target rules will move
## here when moves gain target-count metadata.

signal summary_changed(summary: Dictionary)

var actor: Character
var move: CombatAction
var _picked: Array[Character] = []
var _last_focused_slot: SelectionSlot
var _cancel_watcher: _CancelWatcher


func _init(p_actor: Character, p_move: CombatAction) -> void:
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
	if initial:
		initial.grab_focus.call_deferred()

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
	var gate := _TargetGate.new()
	for slot in slots:
		slot.user_selected.connect(gate.on_selected)
	_install_cancel_watcher(gate)

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

	for slot in slots:
		if slot.user_selected.is_connected(gate.on_selected):
			slot.user_selected.disconnect(gate.on_selected)
	_uninstall_cancel_watcher()

	return result


func _install_cancel_watcher(gate: _TargetGate) -> void:
	_cancel_watcher = _CancelWatcher.new()
	_cancel_watcher.gate = gate
	Engine.get_main_loop().root.add_child(_cancel_watcher)


func _uninstall_cancel_watcher() -> void:
	if _cancel_watcher:
		_cancel_watcher.queue_free()
		_cancel_watcher = null


class _TargetGate extends RefCounted:
	signal tick
	var picked_slot: SelectionSlot
	var cancelled: bool = false

	func on_selected(slot: SelectionSlot) -> void:
		picked_slot = slot
		tick.emit()

	func on_cancel() -> void:
		cancelled = true
		tick.emit()


class _CancelWatcher extends Node:
	var gate: _TargetGate

	func _input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel") and gate:
			get_viewport().set_input_as_handled()
			gate.on_cancel()
