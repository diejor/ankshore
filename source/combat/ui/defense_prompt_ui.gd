class_name DefensePromptUI extends Control

## Cue shown when the local team's defender has an open block window.
##
## Visualizes the incoming [AttackBeat] and a countdown, hides once the
## controller closes the window. Bind to the local [TeamManager] - the
## AI's own defenses do not need a prompt.

@export var team: TeamManager:
	set(value):
		_disconnect_team()
		team = value
		_connect_team()

@onready var _beat_view: AttackStringView = $Panel/VBox/AttackStringView
@onready var _label: Label = $Panel/VBox/Label
@onready var _timer_bar: ProgressBar = $Panel/VBox/TimerBar

enum Stage { HIDDEN, ACTIVE, RESULT }

const RESULT_HOLD_SEC := 0.4

var _window_remaining: float = 0.0
var _result_remaining: float = 0.0
var _stage: Stage = Stage.HIDDEN
var _active_character: Character = null


func _ready() -> void:
	hide()
	set_process(false)
	_connect_team()
	_check_wiring.call_deferred()


func _check_wiring() -> void:
	if team == null:
		push_warning("DefensePromptUI: 'team' is not bound.")


func _connect_team() -> void:
	if team == null:
		return
	if not team.character_defense_window_opened.is_connected(
		_on_window_opened
	):
		team.character_defense_window_opened.connect(_on_window_opened)
	if not team.character_defense_window_closed.is_connected(_on_closed):
		team.character_defense_window_closed.connect(_on_closed)
	if not team.character_beat_resolved.is_connected(_on_beat_resolved):
		team.character_beat_resolved.connect(_on_beat_resolved)


func _disconnect_team() -> void:
	if team == null:
		return
	if team.character_defense_window_opened.is_connected(_on_window_opened):
		team.character_defense_window_opened.disconnect(_on_window_opened)
	if team.character_defense_window_closed.is_connected(_on_closed):
		team.character_defense_window_closed.disconnect(_on_closed)
	if team.character_beat_resolved.is_connected(_on_beat_resolved):
		team.character_beat_resolved.disconnect(_on_beat_resolved)


func _on_window_opened(
	_character: Character,
	beat: AttackBeat,
	window_sec: float
) -> void:
	_active_character = _character
	_label.text = "Block!"
	_label.modulate = Color.WHITE
	var s := AttackString.new()
	s.beats = [beat]
	_beat_view.attack_string = s
	_start_window(window_sec)


func _on_closed(
	_character: Character,
	_result: DefenseInput
) -> void:
	if _character != _active_character:
		return
	_stage = Stage.RESULT
	set_process(false)


func _on_beat_resolved(
	character: Character,
	_beat: AttackBeat,
	blocked: bool,
	damage: int
) -> void:
	if character != _active_character:
		return
	if blocked and damage <= 0:
		_show_result("BLOCKED", Color(0.25, 0.9, 0.35))
	elif blocked:
		_show_result("CHIP -%d" % damage, Color(1.0, 0.85, 0.2))
	else:
		_show_result("HIT -%d" % damage, Color(1.0, 0.2, 0.15))


func _show_result(text: String, color: Color) -> void:
	_label.text = text
	_label.modulate = color
	_result_remaining = RESULT_HOLD_SEC
	_stage = Stage.RESULT
	show()
	set_process(true)


func _hide_prompt() -> void:
	_active_character = null
	_stage = Stage.HIDDEN
	hide()
	set_process(false)


func _start_window(window_sec: float) -> void:
	_window_remaining = window_sec
	_stage = Stage.ACTIVE
	_timer_bar.max_value = window_sec
	_timer_bar.value = window_sec
	show()
	set_process(true)


func _process(delta: float) -> void:
	if _stage == Stage.ACTIVE:
		_window_remaining = max(0.0, _window_remaining - delta)
		_timer_bar.value = _window_remaining
	elif _stage == Stage.RESULT:
		_result_remaining = max(0.0, _result_remaining - delta)
		if _result_remaining <= 0.0:
			_hide_prompt()
