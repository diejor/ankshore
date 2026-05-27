class_name DefensePromptUI extends Control

## Cue shown when the local team's defender has an open defense window.
##
## Visualizes the incoming [AttackBeat] (or parry prompt) and a countdown,
## hides once the controller closes the window. Bind to the local
## [TeamManager] - the AI's own defenses do not need a prompt.

@export var team: TeamManager:
	set(value):
		_disconnect_team()
		team = value
		_connect_team()

@onready var _beat_view: AttackStringView = $Panel/VBox/AttackStringView
@onready var _label: Label = $Panel/VBox/Label
@onready var _timer_bar: ProgressBar = $Panel/VBox/TimerBar

var _window_remaining: float = 0.0


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


func _disconnect_team() -> void:
	if team == null:
		return
	if team.character_defense_window_opened.is_connected(_on_window_opened):
		team.character_defense_window_opened.disconnect(_on_window_opened)
	if team.character_defense_window_closed.is_connected(_on_closed):
		team.character_defense_window_closed.disconnect(_on_closed)


func _on_window_opened(
	_character: Character,
	kind: Character.DefenseKind,
	beat: AttackBeat,
	window_sec: float
) -> void:
	if kind == Character.DefenseKind.BLOCK:
		_label.text = "Block!"
		var s := AttackString.new()
		s.beats = [beat]
		s.ender = AttackString.Ender.STRIKE
		_beat_view.attack_string = s
	else:
		_label.text = "Parry!"
		_beat_view.attack_string = null
	_start_window(window_sec)


func _on_closed(
	_character: Character,
	_result: DefenseInput
) -> void:
	hide()
	set_process(false)


func _start_window(window_sec: float) -> void:
	_window_remaining = window_sec
	_timer_bar.max_value = window_sec
	_timer_bar.value = window_sec
	show()
	set_process(true)


func _process(delta: float) -> void:
	_window_remaining = max(0.0, _window_remaining - delta)
	_timer_bar.value = _window_remaining
