extends Label

## Label that manages and displays the active turn countdown timer.

@onready var _turn_timer: Timer = %TurnTimer
@onready var _unfmt_text: String = text


func _ready() -> void:
	text = _unfmt_text % int(_turn_timer.time_left)


# Fired on periodic seconds beats to update timer numbers visually.
func _on_seconds_beat_timeout() -> void:
	text = _unfmt_text % int(_turn_timer.time_left)


# Restarts the countdown timer when a new turn starts.
func _on_turn_manager_turn_started(_team: TeamManager) -> void:
	_turn_timer.start()
