class_name MatchHud extends Control

## Top-of-screen HUD: turn team, turn number, phase banner.
##
## Subscribes to [TurnManager] signals. Phase animations live on an
## optional [AnimationPlayer] + [SimpleAnimator] child wired into
## [member PhaseContext.ui_animator] from [CombatScene] - this script
## does not assume one exists.

@export var turn_manager: TurnManager

@onready var _turn_label: Label = $HBox/TurnLabel
@onready var _turn_number: Label = $HBox/TurnNumberLabel
@onready var _phase_banner: Label = $HBox/PhaseBanner


func _ready() -> void:
	if turn_manager == null:
		push_warning("MatchHud has no TurnManager bound.")
		return
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.planning_finished.connect(_on_planning_finished)
	turn_manager.match_ended.connect(_on_match_ended)
	_phase_banner.text = ""


func _on_turn_started(team: TeamManager) -> void:
	_turn_label.text = "Turn: %s" % team.team_str
	_turn_number.text = "# %d" % turn_manager.current_turn
	_phase_banner.text = "Planning"


func _on_planning_finished() -> void:
	_phase_banner.text = "Resolution"


func _on_match_ended() -> void:
	_phase_banner.text = "Match Over"
