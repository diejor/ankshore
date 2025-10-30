extends CanvasLayer

@onready var client: GameClient = $"../Client"
@onready var server: GameServer = $"../Server"

@onready var server_ip_edit: TextEdit = $VBoxContainer/HBoxContainer/ServerIpEdit


func _ready() -> void:
	if "--server" in OS.get_cmdline_args():
		visible = false
	
	client.multiplayer_api.connected_to_server.connect(on_connected_to_server)

func join_player():
	var server_ip = server_ip_edit.text
	client.create_client(server_ip)

func on_connected_to_server():
	visible = false


func _on_join_button_pressed() -> void:
	join_player()

func _on_host_button_pressed() -> void:
	var _creation_result = server.create_server()
	join_player()
