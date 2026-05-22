class_name CombatScene extends Node2D

## Entry point for a combat encounter.
##
## The scene file wires the static structure (teams, controllers,
## animators); this script wires the [TeamState]-backed views to the
## runtime-constructed state instances and kicks off
## [method TurnManager.run_match].

@onready var _turn_manager: TurnManager = %TurnManager
@onready var _move_list_ui: MoveListUI = %MoveListUI


func _ready() -> void:
	_bind_views()
	var ctx := PhaseContext.new()
	ctx.turn_manager = _turn_manager
	await _turn_manager.run_match(ctx)


# Attaches each scene-authored view to the [TeamState] of the team it
# observes. State is constructed at runtime in [TeamManager._init], so
# the wiring lives here rather than as a SubResource in the scene file.
func _bind_views() -> void:
	var ally_team := _turn_manager.teams[0] if (
		_turn_manager.teams.size() > 0
	) else null
	if ally_team and _move_list_ui:
		_move_list_ui.team_state = ally_team.state
