class_name CountDown
extends Node

signal frame(time_left: float)
signal timeout

@export var turn_timer: Timer

func _ready() -> void:
	turn_timer.timeout.connect(_on_turn_timeout)

func _process(_delta: float) -> void:
	if not turn_timer.is_stopped():
		frame.emit(turn_timer.time_left)

func _on_turn_timeout() -> void:
	timeout.emit()


func start() -> void:
	turn_timer.start()

func stop() -> void:
	turn_timer.stop()
