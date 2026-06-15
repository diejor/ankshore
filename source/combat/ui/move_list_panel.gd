class_name MoveListContainer extends VBoxContainer

## Lists the moves of the [Character] currently in [InspectionState].
##
## Operates in one of two modes depending on the bound [TeamState]:
## [br]- [constant Mode.COMMIT]: focusable buttons; click calls
##   [method TeamState.select_move]. Engaged when the inspected character
##   is the team's [member TeamState.active_character] in
##   [constant TeamState.Phase.PICKING_MOVE].
## [br]- [constant Mode.INSPECT]: read-only labels. Engaged otherwise,
##   including when inspecting an enemy.

enum Mode { INSPECT, COMMIT }

@export var inspection: InspectionState:
	set(value):
		if inspection:
			inspection.inspection_changed.disconnect(_on_inspection_changed)
		inspection = value
		if inspection:
			inspection.inspection_changed.connect(_on_inspection_changed)
			if is_node_ready():
				_rebuild()

## [TeamState] consulted to choose [enum Mode] and to commit moves in
## [constant Mode.COMMIT].
@export var team_state: TeamState:
	set(value):
		if team_state:
			team_state.phase_changed.disconnect(_on_phase_changed)
			team_state.active_character_changed.disconnect(_on_active_changed)
		team_state = value
		if team_state:
			team_state.phase_changed.connect(_on_phase_changed)
			team_state.active_character_changed.connect(_on_active_changed)
			if is_node_ready():
				_rebuild()

# Items in current display order. Buttons in COMMIT mode, labels in INSPECT.
var _items: Array[Control] = []
var _last_focused_index: int = 0


func _ready() -> void:
	_rebuild()


func _on_inspection_changed(_c: Character) -> void:
	_rebuild()


func _on_phase_changed(_phase: int) -> void:
	_rebuild()


func _on_active_changed(_c: Character) -> void:
	_rebuild()


func _rebuild() -> void:
	_clear()
	var character := _inspected_character()
	if character == null:
		return
	var moves := character.available_moves()
	var mode := _current_mode(character)
	for i in moves.size():
		var action := moves[i]
		if action == null:
			continue
		var item := _build_item(action, mode, i)
		_items.append(item)
		add_child(item)
	if mode == Mode.COMMIT and not _items.is_empty():
		var idx: int = clamp(_last_focused_index, 0, _items.size() - 1)
		_items[idx].grab_focus.call_deferred()


func _inspected_character() -> Character:
	return inspection.inspected_character if inspection else null


func _current_mode(character: Character) -> int:
	if team_state == null:
		return Mode.INSPECT
	if team_state.phase != TeamState.Phase.PICKING_MOVE:
		return Mode.INSPECT
	if team_state.active_character != character:
		return Mode.INSPECT
	return Mode.COMMIT


func _build_item(action: CharacterAction, mode: int, index: int) -> Control:
	if mode == Mode.COMMIT:
		var button := Button.new()
		button.text = action.name
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_pressed.bind(action))
		button.focus_entered.connect(_on_focused.bind(index))
		return button
	var label := Label.new()
	label.text = action.name
	return label


func _clear() -> void:
	for child in get_children():
		if child.name != "Title":
			child.queue_free()
	_items.clear()


func _on_pressed(action: CharacterAction) -> void:
	if team_state:
		team_state.select_move(action)


func _on_focused(index: int) -> void:
	_last_focused_index = index
