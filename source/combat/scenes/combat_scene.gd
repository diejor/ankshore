class_name CombatScene extends Node2D

## Entry point for a combat encounter.
##
## The scene file wires the static structure (teams, controllers,
## animators); this script constructs the shared runtime state
## ([InspectionState], [PhaseContext]), binds views to the
## [TeamState]-backed models, and kicks off [method TurnManager.run_match].

@onready var _turn_manager: TurnManager = %TurnManager
@onready var _move_list_ui: MoveListUI = %MoveListUI
@onready var _slot_selection_view: SlotSelectionView = (
	get_node_or_null("%SlotSelectionView")
)

var _inspection: InspectionState


func _ready() -> void:
	_inspection = InspectionState.new()
	_bind_views()
	var ctx := PhaseContext.new()
	ctx.turn_manager = _turn_manager
	ctx.inspection_state = _inspection
	await _turn_manager.run_match(ctx)


# Attaches scene-authored views to the runtime state they observe.
# [TeamState] is constructed in [TeamManager._init] and
# [InspectionState] is constructed above, so wiring lives here rather
# than as SubResources in the scene file.
func _bind_views() -> void:
	var ally_team := _turn_manager.teams[0] if (
		_turn_manager.teams.size() > 0
	) else null
	if ally_team and _move_list_ui:
		_move_list_ui.team_state = ally_team.state
	if _slot_selection_view:
		_slot_selection_view.inspection = _inspection
