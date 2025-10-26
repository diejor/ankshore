extends CharacterBody2D

@export var speed: float = 3.
@export var sprint_speed: float = 7.

func _physics_process(_delta: float) -> void:
	
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_pressed("sprint"):
		position += input*sprint_speed
	else:
		position += input*speed
	
