extends CharacterBody2D

@export var speed = 3.

func _physics_process(_delta: float) -> void:
	
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var ifSprint = 0.
	if Input.is_action_pressed("run_Toggle"):
		ifSprint = 7.
	else:
		ifSprint = 0.	
	var speedHolder = ifSprint+ speed
	position += input*speedHolder
	
