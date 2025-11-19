extends CharacterBody2D

@onready var input: PlayerInputComponent = %InputComponent

@export var walk_speed := 64.0
@export var sprint_speed := 80.0

func _physics_process(_delta: float) -> void:
	var desired_speed: float
	if input.sprinting:
		desired_speed = sprint_speed 
	else:
		desired_speed = walk_speed

	velocity = desired_speed * input.direction
	
	move_and_slide()
