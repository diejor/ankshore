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
		if inspection:
			inspection.inspection_changed.disconnect(_on_inspection_changed)
		inspection = value
		if inspection:
			inspection.inspection_changed.connect(_on_inspection_changed)
		if is_node_ready():
			_character_panel.inspection = inspection
			_move_list_panel.inspection = inspection
			_refresh_preview()

@export var team_state: TeamState:
	set(value):
		if team_state:
			team_state.move_selected.disconnect(_on_move_selected)
		team_state = value
		if team_state:
			team_state.move_selected.connect(_on_move_selected)
		if is_node_ready():
			_move_list_panel.team_state = team_state
			_refresh_preview()

@onready var _character_panel: CharacterPanel = %CharacterPanel
@onready var _move_list_panel: MoveListContainer = %MoveListContainer
@onready var _attack_string_view: AttackStringView = %AttackStringView


func _ready() -> void:
	_character_panel.inspection = inspection
	_move_list_panel.inspection = inspection
	_move_list_panel.team_state = team_state
	hide()
	_check_wiring.call_deferred()


func _check_wiring() -> void:
	if inspection == null:
		push_warning("PlanningPanel: 'inspection' is not bound. Inspection features will be inert.")
	if team_state == null:
		push_warning("PlanningPanel: 'team_state' is not bound. Moves list and commit functions will be inert.")


## Subscribes to [param tm] for show/hide cues. Call once from
## [CombatScene] after construction.
func bind_turn_manager(tm: TurnManager) -> void:
	tm.turn_started.connect(_on_turn_started)
	tm.planning_finished.connect(_on_planning_finished)
	tm.match_ended.connect(hide)


func _on_turn_started(_team: TeamManager) -> void:
	_refresh_preview()
	show()


func _on_planning_finished() -> void:
	hide()


# Picks the most relevant string to preview: the actively-selected move
# if it is an [AttackString], otherwise the inspected character's first
# [AttackString], otherwise none.
func _refresh_preview() -> void:
	var preview: AttackString = null
	if team_state and team_state.selected_move is AttackString:
		preview = team_state.selected_move
	else:
		var c := inspection.inspected_character if inspection else null
		if c:
			for m in c.available_moves():
				if m is AttackString:
					preview = m
					break
	_attack_string_view.attack_string = preview


func _on_inspection_changed(_c: Character) -> void:
	_refresh_preview()


func _on_move_selected(_move: CombatAction) -> void:
	_refresh_preview()
