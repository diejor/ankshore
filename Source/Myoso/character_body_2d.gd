extends CharacterBody2D

# Use `InputComponent` to handle input inside `_unhandled_input` callback,
# very important to not leak input to the controller when using UI elements.
@onready var input : InputComponent = %InputComponent

@export var walk_speed = 64.0
@export var sprint_speed = 80.0


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	var input_dir = input.get_vector2("move_left", "move_right", "move_up", "move_down")

	var desired_speed = sprint_speed if input.is_down("sprint") else walk_speed

	velocity = desired_speed * input_dir
	move_and_slide()
