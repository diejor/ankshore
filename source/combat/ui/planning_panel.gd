class_name PlanningPanel extends HBoxContainer

## Container for the planning sub-panels. Shows during a planning phase
## and hides during resolution.
##
## Wiring: assign [member inspection] (shared across the encounter) and
## [member team_state] (the local team's state). The panel forwards both
## to its child widgets and listens to [TurnManager] via
## [method bind_turn_manager] for visibility.

@export var inspection: InspectionState:
	set(value):
		inspection = value
		if is_node_ready():
			_character_panel.inspection = inspection
			_move_list_panel.inspection = inspection

@export var team_state: TeamState:
	set(value):
		team_state = value
		if is_node_ready():
			_move_list_panel.team_state = team_state

@onready var _character_panel: CharacterPanel = %CharacterPanel
@onready var _move_list_panel: MoveListContainer = %MoveListContainer
@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_character_panel.inspection = inspection
	_move_list_panel.inspection = inspection
	_move_list_panel.team_state = team_state
	modulate.a = 0.0
	hide()
	_check_wiring.call_deferred()


func _check_wiring() -> void:
	if inspection == null:
		push_warning(
			"PlanningPanel: 'inspection' is not bound. "
			+ "Inspection features will be inert."
		)
	if team_state == null:
		push_warning(
			"PlanningPanel: 'team_state' is not bound. "
			+ "Moves list and commit functions will be inert."
		)


## Subscribes to [param tm] for show/hide cues. Call once from
## [CombatScene] after construction.
func bind_turn_manager(tm: TurnManager) -> void:
	tm.turn_started.connect(_on_turn_started)
	tm.planning_finished.connect(_on_planning_finished)
	tm.match_ended.connect(_on_match_ended)


func _on_turn_started(_team: TeamManager) -> void:
	show()
	_anim.play("slide_in")


func _on_planning_finished() -> void:
	_play_out_and_hide()


func _on_match_ended() -> void:
	_play_out_and_hide()


# Plays the transition out before hiding the panel.
func _play_out_and_hide() -> void:
	if not visible:
		return
	_anim.play("slide_out")
	await _anim.animation_finished
	hide()
