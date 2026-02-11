extends Button

@export var network: Network
@export_file var player_scene: String

@onready var play_game: Label = $PlayGame
@onready var username_edit: LineEdit = %UsernameEdit


var username: String:
	get:
		if username.is_empty():
			var candidate := OS.get_environment("USERNAME")
			if candidate.is_empty():
				candidate = "player"
			username = candidate
		return username

func _on_pressed() -> void:
	var client_data := {
		username = username,
		scene_path = player_scene,
	}
	
	network.configure(client_data)
	get_tree().change_scene_to_node.call_deferred(network)
