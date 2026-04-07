extends Button

@export var network: NetworkSession
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "SceneNodePath:ClientComponent")
var spawner_path: SceneNodePath

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

func _init() -> void:
	var node := Node.new()
	add_child(node)

func _on_pressed() -> void:
	var client_data := MultiplayerClientData.new()
	client_data.username = username
	client_data.spawner_path = spawner_path
	
	network.connect_player(client_data)
