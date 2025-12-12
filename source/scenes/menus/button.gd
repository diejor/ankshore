extends Button
@export var winterScene: PackedScene

@onready var play_game: Label = $PlayGame
@onready var connecting: Label = $Connecting

const MYOSO: PackedScene = preload("uid://bxpx2n4hugojx")

func _ready() -> void:
	disabled = true
	flip_labels()


func flip_labels() -> void:
	play_game.visible = not play_game.visible
	connecting.visible = not play_game.visible


func _on_pressed() -> void:
	var client_data: Dictionary = {
		username = Client.username,
		peer_id = Client.uid,
		scene = MYOSO.resource_path
	}
	Client.level_manager.connect_player.rpc_id(
		MultiplayerPeer.TARGET_PEER_SERVER, client_data)
	get_tree().unload_current_scene.call_deferred()

func on_connected_to_server() -> void:
	disabled = false
	flip_labels()
