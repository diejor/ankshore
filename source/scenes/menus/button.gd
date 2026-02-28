extends Button

@export var network: MultiplayerNetwork
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
	var client_data := MultiplayerClientData.new()
	client_data.username = username
	client_data.scene_path = player_scene
	
	network.connect_player(client_data)
