extends CanvasLayer

@onready var server_ip_edit: TextEdit = %ServerIpEdit
@onready var username_edit: TextEdit = %UsernameEdit


func _ready() -> void:
	if "--server" in OS.get_cmdline_args():
		visible = false
	
	# Already online, no need for ConnectUI
	if get_multiplayer_authority() != 1:
		visible = false
	
	GameInstance.client.multiplayer_api.connected_to_server.connect(on_connected_to_server)

func on_connected_to_server():
	visible = false

func _on_join_button_pressed() -> void:
	var server_address := server_ip_edit.text
	var username := username_edit.text
	GameInstance.client.init(server_address, username)
