extends CharacterBody2D

@export var speed = 25.

func _physics_process(_delta: float) -> void:
	
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += input*speed
