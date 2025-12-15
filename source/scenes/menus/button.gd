extends Button
@export var winterScene: PackedScene

@onready var play_game: Label = $PlayGame
@onready var connecting: Label = $Connecting
@onready var username_edit: LineEdit = %UsernameEdit

const MYOSO: PackedScene = preload("uid://bxpx2n4hugojx")

func _ready() -> void:
	disabled = true
	flip_labels()


func flip_labels() -> void:
	play_game.visible = not play_game.visible
	connecting.visible = not play_game.visible


func _on_pressed() -> void:
	var username: String
	if username_edit.text.is_empty():
		username = Client.username
	else:
		username = username_edit.text
	var client_data: Dictionary = {
		username = username,
		peer_id = Client.uid,
		scene = MYOSO.resource_path
	}
	Client.level_manager.connect_player.rpc_id(
		MultiplayerPeer.TARGET_PEER_SERVER, client_data)
	get_tree().unload_current_scene.call_deferred()

func on_connected_to_server() -> void:
	disabled = false
	flip_labels()
