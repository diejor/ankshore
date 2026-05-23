class_name MatchHud extends Control

## Top-of-screen HUD: turn team, turn number, phase banner.
##
## Subscribes to [TurnManager] signals. Phase animations live on an
## optional [AnimationPlayer] + [SimpleAnimator] child wired into
## [member PhaseContext.ui_animator] from [CombatScene] - this script
## does not assume one exists.

@export var turn_manager: TurnManager:
	set(value):
		if turn_manager:
			turn_manager.turn_started.disconnect(_on_turn_started)
			turn_manager.planning_finished.disconnect(_on_planning_finished)
			turn_manager.match_ended.disconnect(_on_match_ended)
		turn_manager = value
		if turn_manager:
			turn_manager.turn_started.connect(_on_turn_started)
			turn_manager.planning_finished.connect(_on_planning_finished)
			turn_manager.match_ended.connect(_on_match_ended)

@onready var _turn_label: Label = $HBox/TurnLabel
@onready var _turn_number: Label = $HBox/TurnNumberLabel
@onready var _phase_banner: Label = $HBox/PhaseBanner


func _ready() -> void:
	_phase_banner.text = ""
	_check_wiring.call_deferred()


func _check_wiring() -> void:
	if turn_manager == null:
		push_warning("MatchHud: 'turn_manager' is not bound. The HUD will be non-functional.")


func _on_turn_started(team: TeamManager) -> void:
	_turn_label.text = "Turn: %s" % team.team_str
	_turn_number.text = "# %d" % turn_manager.current_turn
	_phase_banner.text = "Planning"


func _on_planning_finished() -> void:
	_phase_banner.text = "Resolution"


func _on_match_ended() -> void:
	_phase_banner.text = "Match Over"
