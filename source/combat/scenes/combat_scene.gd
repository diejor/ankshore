class_name CombatScene extends Node2D

## Entry point for a combat encounter.
##
## The scene file wires everything: teams, controllers, UI labels,
## animators. This script only builds the [PhaseContext] from the
## scene's nodes and kicks off [method TurnManager.run_match].

@onready var _turn_manager: TurnManager = %TurnManager


func _ready() -> void:
	var ctx := PhaseContext.new()
	ctx.turn_manager = _turn_manager
	await _turn_manager.run_match(ctx)
