extends Button
@export var winterScene: PackedScene

@onready var play_game: Label = $PlayGame
@onready var connecting: Label = $Loading
@onready var username_edit: LineEdit = %UsernameEdit

const MYOSO: PackedScene = preload("uid://bxpx2n4hugojx")

func _ready() -> void:
	disabled = true
	flip_labels()

func flip_labels() -> void:
	play_game.visible = not play_game.visible
	connecting.visible = not play_game.visible


func _on_pressed() -> void:	
	var username: String = username_edit.text
	if username.is_empty():
		var candidate := OS.get_environment("USERNAME")
		if candidate.is_empty():
			candidate = "player"
		username = candidate
	
	var client_data: Dictionary = {
		username = username,
		scene_path = MYOSO.resource_path
	}
	
	SceneManager.connect_player(client_data)


func _on_connected_to_server() -> void:
	disabled = false
	flip_labels()
