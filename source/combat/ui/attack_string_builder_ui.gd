class_name AttackStringBuilderUI extends Control

## Interactive panel for the local attacker to assemble an [AttackString].
##
## Shown when the bound [TeamState] enters
## [constant TeamState.Phase.BUILDING_STRING]. Directional presses append
## [AttackBeat]s (horizontal selects side, vertical selects direction);
## [code]ui_accept[/code] seals early. The string also seals when it hits
## the move's [member CombatAction.max_beats] or when the build timer runs
## out. Seals via [method TeamState.commit_string].
##
## [br][br]
## Bind to the local team's [TeamState]; the AI builds its own strings
## without a panel.

@export var team_state: TeamState:
	set(value):
		_disconnect_state()
		team_state = value
		_connect_state()

@onready var _label: Label = $Panel/VBox/Label
@onready var _string_view: AttackStringView = $Panel/VBox/AttackStringView
@onready var _timer_bar: ProgressBar = $Panel/VBox/TimerBar

var _move: CombatAction = null
var _beats: Array[AttackBeat] = []
var _remaining: float = 0.0
var _active: bool = false


func _ready() -> void:
	hide()
	set_process(false)
	_connect_state()


func _connect_state() -> void:
	if team_state == null:
		return
	if not team_state.string_building_started.is_connected(_on_started):
		team_state.string_building_started.connect(_on_started)
	if not team_state.phase_changed.is_connected(_on_phase_changed):
		team_state.phase_changed.connect(_on_phase_changed)


func _disconnect_state() -> void:
	if team_state == null:
		return
	if team_state.string_building_started.is_connected(_on_started):
		team_state.string_building_started.disconnect(_on_started)
	if team_state.phase_changed.is_connected(_on_phase_changed):
		team_state.phase_changed.disconnect(_on_phase_changed)


func _on_started(
	move: CombatAction, _targets: Array[Character]
) -> void:
	_move = move
	_beats = []
	_remaining = move.build_time_sec
	_active = true
	_timer_bar.max_value = move.build_time_sec
	_timer_bar.value = move.build_time_sec
	_refresh_view()
	show()
	set_process(true)


# Closes without committing when the step is left by back-navigation.
func _on_phase_changed(phase: TeamState.Phase) -> void:
	if phase != TeamState.Phase.BUILDING_STRING and _active:
		_close()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_accept"):
		_seal()
		return
	var beat := _beat_from_input(event)
	if beat == null:
		return
	_beats.append(beat)
	_refresh_view()
	if _move and _beats.size() >= _move.max_beats:
		_seal()


# Maps a directional press (held horizontal + optional vertical) to a beat.
func _beat_from_input(event: InputEvent) -> AttackBeat:
	var triggered := false
	for action: String in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		if event.is_action_pressed(action):
			triggered = true
			break
	if not triggered:
		return null
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var down := Input.is_action_pressed("ui_down")
	if not left and not right:
		return null
	var beat := AttackBeat.new()
	beat.side = AttackBeat.StrikeSide.FRONT if left \
		else AttackBeat.StrikeSide.BEHIND
	beat.direction = AttackBeat.Direction.LOW if down \
		else AttackBeat.Direction.OVERHEAD
	return beat


func _seal() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	hide()
	team_state.commit_string(_beats)


func _close() -> void:
	_active = false
	set_process(false)
	hide()


func _refresh_view() -> void:
	var preview := AttackString.new()
	preview.beats = _beats
	_string_view.attack_string = preview
	var cap: int = _move.max_beats if _move else 0
	_label.text = "Build String  %d / %d" % [_beats.size(), cap]


func _process(delta: float) -> void:
	_remaining = max(0.0, _remaining - delta)
	_timer_bar.value = _remaining
	if _remaining <= 0.0:
		_seal()
