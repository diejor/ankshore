class_name MoveListUI extends Control

## Focusable list of moves shown during a [MoveSelectionStep].
##
## [method present] rebuilds the buttons for the given actor and grabs
## focus on the first one. Picking a button emits [signal move_picked];
## pressing [code]ui_cancel[/code] emits [signal cancelled].

signal move_picked(action: CombatAction)
signal cancelled

var _container: VBoxContainer
var _buttons: Array[Button] = []
var _last_focused_index: int = 0


func _ready() -> void:
	_container = VBoxContainer.new()
	add_child(_container)
	hide()


## Rebuilds the button list for [param actor]'s moves and grabs focus.
##
## The cursor is restored to its previous position when the same actor
## re-enters move selection after backing out of target picking.
func present(actor: Character) -> void:
	_clear()
	var moves := actor.available_moves()
	for i in moves.size():
		var action := moves[i]
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


## Hides the list and clears its buttons.
func dismiss() -> void:
	hide()
	_clear()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		cancelled.emit()


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _on_pressed(action: CombatAction) -> void:
	move_picked.emit(action)


func _on_button_focused(index: int) -> void:
	_last_focused_index = index
