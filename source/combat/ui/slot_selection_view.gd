class_name SlotSelectionView extends Node

## View that drives [SelectionSlot] focus and step-mode from a [TeamState].
##
## Subscribes to [signal TeamState.phase_changed] and toggles
## [enum SelectionSlot.StepMode] on the bound [member team]'s slots (own
## team during [constant TeamState.Phase.PICKING_CHARACTER], opposing team
## during [constant TeamState.Phase.PICKING_TARGETS]). Remembers the slot
## focused at each step so back-navigation restores the prior choice.
##
## [br][br]
## Add one under any team whose human player needs on-screen selection
## affordances. AI-only teams do not need it. Controllers stay pure
## input -> state; this node owns the visual feedback.

## Team whose [TeamState] this view observes.
@export var team: TeamManager

## Shared inspection target. Set by [CombatScene]; this view pushes the
## focused slot's character into [member InspectionState.inspected_character]
## so panels stay in sync with slot navigation.
var inspection: InspectionState = null

# Slot focused last during PICKING_CHARACTER. Used to restore focus when
# re-entering that phase after a back-nav.
var _last_character_slot: SelectionSlot = null

# Slot focused last during PICKING_TARGETS.
var _last_target_slot: SelectionSlot = null

# Phase before the current one, used to attribute the focused slot to
# the step the player just left.
var _previous_phase: int = TeamState.Phase.IDLE


func _ready() -> void:
	if team == null:
		push_error("SlotSelectionView has no bound TeamManager.")
		return
	var s := team.state
	if s == null:
		push_error("SlotSelectionView: team has no TeamState.")
		return
	s.phase_changed.connect(_on_phase_changed)
	s.active_character_changed.connect(_on_active_changed)
	_connect_focus_listeners.call_deferred()
	_on_phase_changed(s.phase)


func _on_phase_changed(phase: TeamState.Phase) -> void:
	_stash_focus_for(_previous_phase)
	_clear_slot_modes()
	_previous_phase = phase
	match phase:
		TeamState.Phase.PICKING_CHARACTER:
			_enter_pick_character()
		TeamState.Phase.PICKING_TARGETS:
			_enter_pick_targets()


# Marks own-team slots holding pending characters as selectable and
# focuses the most relevant one.
func _enter_pick_character() -> void:
	var first: SelectionSlot = null
	var pending := team.state.pending_characters
	for slot in team.slots:
		var c := slot.get_character()
		if c and pending.has(c):
			slot.set_step_mode(SelectionSlot.StepMode.SELECTABLE_OWN)
			if first == null:
				first = slot
	_focus_or_fallback(_last_character_slot, first)


# Marks live opponents as targetable and focuses one.
func _enter_pick_targets() -> void:
	var enemy := team.get_other_team()
	if enemy == null:
		return
	var first: SelectionSlot = null
	for slot in enemy.slots:
		var c := slot.get_character()
		if c and c.is_alive():
			slot.set_step_mode(SelectionSlot.StepMode.SELECTABLE_TARGET)
			if first == null:
				first = slot
	_focus_or_fallback(_last_target_slot, first)


# Pins inspection to the active character during PICKING_MOVE, since no
# slot is focused during that phase. Other phases derive inspection from
# slot focus directly.
func _on_active_changed(c: Character) -> void:
	if inspection == null or c == null:
		return
	if team.state.phase == TeamState.Phase.PICKING_MOVE:
		inspection.inspected_character = c


# Connects [signal Control.focus_entered] on every slot the player can
# navigate to (own team plus the opposing team's slots) so inspection
# updates reactively. Deferred to give [TeamManager] time to resolve its
# opponent via [code]%TurnManager[/code].
func _connect_focus_listeners() -> void:
	for slot in team.slots:
		slot.focus_entered.connect(_on_slot_focused.bind(slot))
	var enemy := team.get_other_team()
	if enemy:
		for slot in enemy.slots:
			slot.focus_entered.connect(_on_slot_focused.bind(slot))


func _on_slot_focused(slot: SelectionSlot) -> void:
	if inspection == null:
		return
	var c := slot.get_character()
	if c:
		inspection.inspected_character = c


# Captures the currently focused slot before slot modes are cleared, so
# back-nav can restore it on re-entry.
func _stash_focus_for(phase: int) -> void:
	var vp := get_viewport()
	var focused := vp.gui_get_focus_owner() if vp else null
	if focused is not SelectionSlot:
		return
	match phase:
		TeamState.Phase.PICKING_CHARACTER:
			_last_character_slot = focused
		TeamState.Phase.PICKING_TARGETS:
			_last_target_slot = focused


func _focus_or_fallback(
	preferred: SelectionSlot, fallback: SelectionSlot
) -> void:
	var target := preferred if (
		preferred
		and preferred.step_mode != SelectionSlot.StepMode.INERT
	) else fallback
	if target:
		target.grab_focus.call_deferred()


func _clear_slot_modes() -> void:
	for slot in team.slots:
		slot.set_step_mode(SelectionSlot.StepMode.INERT)
	var enemy := team.get_other_team()
	if enemy:
		for slot in enemy.slots:
			slot.set_step_mode(SelectionSlot.StepMode.INERT)
