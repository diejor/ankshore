extends Label

## Label that visually displays which team's turn is currently active.

@onready var _unfmt_text: String = text


# Triggered when TurnManager starts a turn. Updates label text.
func _on_turn_manager_turn_started(team: TeamManager) -> void:
	text = _unfmt_text % team.team_str
