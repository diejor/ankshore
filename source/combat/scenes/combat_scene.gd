class_name CombatScene extends Node2D

## Entry point and coordinator for a combat encounter.
##
## Builds the [PhaseContext] (animators, move list UI), then awaits
## [method TurnManager.run_match]. Scene-level animation drivers are
## attached here so phases never reach into the scene tree directly.

@onready var _turn_manager: TurnManager = %TurnManager
@onready var _canvas_layer: CanvasLayer = $CanvasLayer

var _move_list_ui: MoveListUI


func _ready() -> void:
	_move_list_ui = MoveListUI.new()
	_move_list_ui.set_anchors_preset(Control.PRESET_CENTER)
	_canvas_layer.add_child(_move_list_ui)

	var ctx := PhaseContext.new()
	ctx.turn_manager = _turn_manager
	ctx.move_list_ui = _move_list_ui
	await _turn_manager.run_match(ctx)
