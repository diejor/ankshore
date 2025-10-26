extends CharacterBody2D

@export var walk_speed: float = 3.
@export var sprint_speed: float = 7.

func _physics_process(_delta: float) -> void:
	
	var movement_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var desired_speed: float
	if Input.is_action_pressed("sprint"):
		desired_speed = sprint_speed
	else:
		desired_speed = walk_speed
	
	# I think is better to use the functions that CharacterBody2D gives to move the player
	velocity = desired_speed * movement_input
	move_and_slide()
