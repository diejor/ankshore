class_name turnManager extends Node
signal turnEnded
signal turnStart
signal matchStart

enum Teams {
	Ally,
	Enemy
}

var current_team: Teams = Teams.Ally

@onready var turn_label: DebugLabel = %TurnLabel

func _ready() -> void:
	pass

func update_turn_label() -> void:
	var label_text: String = "Turn %s"
	

func next_turn() -> void:
	pass
