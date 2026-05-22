extends Label

@onready var _turn_manager: TurnManager = %TurnManager
@onready var _unfmt_text: String = text

func _on_turn_manager_turn_started(_team: TeamManager) -> void:
	text = _unfmt_text % _turn_manager.current_turn
