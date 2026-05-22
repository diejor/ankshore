class_name PlayerController extends TeamController

## [TeamController] driven by local input.
##
## Pure input -> state. Confirms the focused [SelectionSlot] into the
## current [TeamState] step, [code]ui_cancel[/code] backs out, and during
## defense windows directional keys or [code]ui_accept[/code] feed
## [method TeamState.complete_defense].
##
## [br][br]
## Owns no view. Slot affordances (focus, step-mode visuals) live on
## [SlotSelectionView]; the move list lives on [MoveListUI]; both bind to
## [member TeamController.state] independently.

# True while a defense window is sampling input. Suppresses normal
# planning-mode dispatch so block/parry presses don't double-fire.
var _defending: bool = false
var _defense_capture: _DefenseCapture = null


func _ready() -> void:
	if state == null:
		push_error("PlayerController has no bound TeamState.")
		return
	state.defense_window_opened.connect(_on_defense_window_opened)
	state.parry_window_opened.connect(_on_parry_window_opened)


func _unhandled_input(event: InputEvent) -> void:
	if _defending and _defense_capture:
		_defense_capture.handle_event(event)
		return
	if state == null:
		return
	if event.is_action_pressed("ui_cancel"):
		state.go_back()
		return
	if event.is_action_pressed("select_character"):
		_handle_slot_confirm()


# Routes the focused slot's character into the appropriate state
# mutation for the current phase.
func _handle_slot_confirm() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is not SelectionSlot:
		return
	var slot: SelectionSlot = focused
	var character := slot.get_character()
	if character == null or not character.is_alive():
		return
	match state.phase:
		TeamState.Phase.PICKING_CHARACTER:
			state.select_character(character)
		TeamState.Phase.PICKING_TARGETS:
			state.commit_targets([character])


func _on_defense_window_opened(
	_beat: AttackBeat, window_sec: float
) -> void:
	_start_capture(_DefenseCapture.Mode.BLOCK, window_sec)


func _on_parry_window_opened(window_sec: float) -> void:
	_start_capture(_DefenseCapture.Mode.PARRY, window_sec)


# Begins listening for one defense reaction. Resolves on the first
# qualifying press or timer expiry.
func _start_capture(mode: int, window_sec: float) -> void:
	var capture := _DefenseCapture.new()
	@warning_ignore("int_as_enum_without_cast")
	capture.mode = mode
	_defense_capture = capture
	_defending = true

	var timer := get_tree().create_timer(window_sec)
	timer.timeout.connect(capture.on_timeout)
	await capture.resolved

	_defending = false
	_defense_capture = null
	var result: DefenseInput = capture.result if capture.result \
		else DefenseInput.none()
	state.complete_defense(result)


## Single-use input gate for one defense window. Resolves on the first
## qualifying press or on timer expiry, whichever comes first.
class _DefenseCapture extends RefCounted:
	## Block samples direction keys; parry samples [code]ui_accept[/code].
	enum Mode { BLOCK, PARRY }

	## Emitted exactly once when the capture resolves (input or timeout).
	signal resolved

	## Which input shape this capture is sampling.
	var mode: Mode = Mode.BLOCK

	## The reaction the user produced, or [code]null[/code] on timeout.
	var result: DefenseInput = null

	# True after [signal resolved] has been emitted.
	var _done: bool = false

	## Feeds [param event] into the capture. No-op once resolved.
	func handle_event(event: InputEvent) -> void:
		if _done:
			return
		if mode == Mode.PARRY:
			if event.is_action_pressed("ui_accept"):
				_finish(DefenseInput.parry())
			return
		var triggered := false
		@warning_ignore("untyped_declaration")
		for action in ["ui_left", "ui_right", "ui_down"]:
			@warning_ignore("unsafe_call_argument")
			if event.is_action_pressed(action):
				triggered = true
				break
		if not triggered:
			return
		var left := Input.is_action_pressed("ui_left")
		var right := Input.is_action_pressed("ui_right")
		var down := Input.is_action_pressed("ui_down")
		if not left and not right:
			return
		var s := AttackBeat.StrikeSide.FRONT if left \
			else AttackBeat.StrikeSide.BEHIND
		var d := AttackBeat.Direction.LOW if down \
			else AttackBeat.Direction.OVERHEAD
		_finish(DefenseInput.block(d, s))

	## Resolves the capture with a null result.
	func on_timeout() -> void:
		if _done:
			return
		_finish(null)

	# Centralizes resolution to keep [member _done] honest.
	func _finish(value: DefenseInput) -> void:
		_done = true
		result = value
		resolved.emit()
