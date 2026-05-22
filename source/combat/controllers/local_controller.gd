class_name LocalController extends TeamController

## Drives planning for a locally-controlled team via input.
##
## Owns this team's [MoveListUI] as a child so its UI surface is scoped
## to the controller's subtree. Translates raw [InputEvent]s into
## controller-scoped signals (see [signal slot_picked],
## [signal back_requested]) which planning steps subscribe to.

@export var move_list_ui: MoveListUI

var _saved_focus: Control


func _ready() -> void:
	if move_list_ui:
		move_list_ui.move_picked.connect(_on_move_list_picked)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
	elif event.is_action_pressed("select_character"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is SelectionSlot:
			slot_picked.emit(focused)


## Shows the move list scoped to this controller. Steps call this
## instead of poking the UI node directly.
func present_move_list(actor: Character) -> void:
	if move_list_ui:
		move_list_ui.present(actor)


## Hides the move list.
func dismiss_move_list() -> void:
	if move_list_ui:
		move_list_ui.dismiss()


## Asks the controller to focus [param target] now (if active) or on
## next [method activate].
func focus_on(target: Control) -> void:
	if target == null:
		return
	if is_active:
		target.grab_focus.call_deferred()
	else:
		_saved_focus = target


func activate() -> void:
	if is_active:
		return
	super.activate()
	if _saved_focus and is_instance_valid(_saved_focus):
		_saved_focus.grab_focus.call_deferred()


func deactivate() -> void:
	if not is_active:
		return
	_saved_focus = get_viewport().gui_get_focus_owner() as Control
	super.deactivate()


func plan_turn(_ctx: PhaseContext) -> Array[CommittedAction]:
	var pending: Array[Character] = team.pending_characters()
	var committed: Array[CommittedAction] = []

	while not pending.is_empty():
		var char_step := CharacterSelectionStep.new(self, pending)
		var character: Character = await char_step.run()
		if character == null:
			continue

		var move_step := MoveSelectionStep.new(self, character)
		var action: CommittedAction = await move_step.run()
		if action == null:
			continue

		committed.append(action)
		pending.erase(character)

	return committed


func _on_move_list_picked(action: CombatAction) -> void:
	if is_active:
		move_picked.emit(action)
