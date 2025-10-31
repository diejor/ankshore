extends CanvasLayer

@onready var game_client: GameClient = $"../Client"
@onready var game_server: GameServer = $"../Server"

@onready var server_ip_edit: TextEdit = %ServerIpEdit


func _ready() -> void:
	if "--server" in OS.get_cmdline_args():
		visible = false
	
	if game_client:
		game_client.multiplayer_api.connected_to_server.connect(on_connected_to_server)

func on_connected_to_server():
	visible = false


func _on_join_button_pressed() -> void:
	var server_address := server_ip_edit.text
	game_client.init(server_address)
