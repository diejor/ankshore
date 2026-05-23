class_name DefensePromptUI extends Control

## Cue shown when the local team's defender has an open defense window.
##
## Visualizes the incoming [AttackBeat] (or parry prompt) and a countdown,
## hides once the controller closes the window. Bind to the local team's
## [TeamState] - the AI's own defenses do not need a prompt.

@export var team_state: TeamState:
	set(value):
		_disconnect_state()
		team_state = value
		_connect_state()

@onready var _beat_view: AttackStringView = $Panel/AttackStringView
@onready var _label: Label = $Panel/Label
@onready var _timer_bar: ProgressBar = $Panel/TimerBar

var _window_remaining: float = 0.0


func _ready() -> void:
	hide()
	set_process(false)
	_connect_state()


func _connect_state() -> void:
	if team_state == null:
		return
	if not team_state.defense_window_opened.is_connected(_on_block_opened):
		team_state.defense_window_opened.connect(_on_block_opened)
	if not team_state.parry_window_opened.is_connected(_on_parry_opened):
		team_state.parry_window_opened.connect(_on_parry_opened)
	if not team_state.defense_window_closed.is_connected(_on_closed):
		team_state.defense_window_closed.connect(_on_closed)


func _disconnect_state() -> void:
	if team_state == null:
		return
	if team_state.defense_window_opened.is_connected(_on_block_opened):
		team_state.defense_window_opened.disconnect(_on_block_opened)
	if team_state.parry_window_opened.is_connected(_on_parry_opened):
		team_state.parry_window_opened.disconnect(_on_parry_opened)
	if team_state.defense_window_closed.is_connected(_on_closed):
		team_state.defense_window_closed.disconnect(_on_closed)


func _on_block_opened(beat: AttackBeat, window_sec: float) -> void:
	_label.text = "Block!"
	var s := AttackString.new()
	s.beats = [beat]
	s.ender = AttackString.Ender.STRIKE
	_beat_view.attack_string = s
	_start_window(window_sec)


func _on_parry_opened(window_sec: float) -> void:
	_label.text = "Parry!"
	_beat_view.attack_string = null
	_start_window(window_sec)


func _start_window(window_sec: float) -> void:
	_window_remaining = window_sec
	_timer_bar.max_value = window_sec
	_timer_bar.value = window_sec
	show()
	set_process(true)


func _on_closed(_result: DefenseInput) -> void:
	hide()
	set_process(false)


func _process(delta: float) -> void:
	_window_remaining = max(0.0, _window_remaining - delta)
	_timer_bar.value = _window_remaining
