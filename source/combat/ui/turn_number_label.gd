extends Label

## Label that displays the current overall turn number of the match.

@onready var _turn_manager: TurnManager = %TurnManager
@onready var _unfmt_text: String = text


# Triggered when TurnManager starts a turn. Updates turn count display.
func _on_turn_manager_turn_started(_team: TeamManager) -> void:
	text = _unfmt_text % _turn_manager.current_turn
