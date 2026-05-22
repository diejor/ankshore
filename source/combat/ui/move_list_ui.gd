class_name MoveListUI extends Control

## Move-picker view bound to a [TeamState].
##
## Shows itself when [member team_state]'s [member TeamState.phase]
## enters [constant TeamState.Phase.PICKING_MOVE]; rebuilds buttons for
## the new [member TeamState.active_character]; calls
## [method TeamState.select_move] on click and hides on any other phase.

## The team whose move-pick phase this widget renders. Subscribed
## lazily via a setter so the binding can be rewired at runtime.
@export var team_state: TeamState:
	set(value):
		_disconnect_state(team_state)
		team_state = value
		_connect_state(team_state)
		if is_node_ready() and team_state:
			_sync_to_phase(team_state.phase)

# Vertical container holding one button per available move.
var _container: VBoxContainer

# Buttons in current display order; cleared by [_clear].
var _buttons: Array[Button] = []

# Index of the button focused last, used to restore focus after
# rebuilds (e.g. after backing out of target selection).
var _last_focused_index: int = 0


func _ready() -> void:
	_container = VBoxContainer.new()
	add_child(_container)
	hide()
	if team_state:
		_sync_to_phase(team_state.phase)


# Wires up signals on a newly-bound TeamState.
func _connect_state(s: TeamState) -> void:
	if s == null:
		return
	s.phase_changed.connect(_on_phase_changed)
	s.active_character_changed.connect(_on_active_changed)


# Detaches signals before swapping bindings.
func _disconnect_state(s: TeamState) -> void:
	if s == null:
		return
	if s.phase_changed.is_connected(_on_phase_changed):
		s.phase_changed.disconnect(_on_phase_changed)
	if s.active_character_changed.is_connected(_on_active_changed):
		s.active_character_changed.disconnect(_on_active_changed)


func _on_phase_changed(phase: TeamState.Phase) -> void:
	_sync_to_phase(phase)


func _on_active_changed(_c: Character) -> void:
	if team_state and team_state.phase == TeamState.Phase.PICKING_MOVE:
		_present(team_state.active_character)


# Shows or dismisses based on the current phase.
func _sync_to_phase(phase: TeamState.Phase) -> void:
	if phase == TeamState.Phase.PICKING_MOVE:
		_present(team_state.active_character)
	else:
		_dismiss()


# Rebuilds the button list for [param actor]'s moves and grabs focus.
func _present(actor: Character) -> void:
	_clear()
	if actor == null:
		return
	var moves := actor.available_moves()
	for i in moves.size():
		var action := moves[i]
		if action == null:
			continue
		var button := Button.new()
		button.text = action.name
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_pressed.bind(action))
		button.focus_entered.connect(_on_button_focused.bind(i))
		_container.add_child(button)
		_buttons.append(button)

	show()
	if _buttons.is_empty():
		return
	var focus_index: int = clamp(
		_last_focused_index, 0, _buttons.size() - 1
	)
	_buttons[focus_index].grab_focus.call_deferred()


# Hides the list and clears its buttons.
func _dismiss() -> void:
	hide()
	_clear()


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _on_pressed(action: CombatAction) -> void:
	if team_state:
		team_state.select_move(action)


func _on_button_focused(index: int) -> void:
	_last_focused_index = index
