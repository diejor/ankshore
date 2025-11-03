extends CanvasLayer

@onready var game_server: GameServer = $"/root/GameInstance/%Network/%GameServer"
@onready var game_client: GameClient = $"/root/GameInstance/%Network/%GameClient"

@onready var server_ip_edit: TextEdit = %ServerIpEdit
@onready var username_edit: TextEdit = %UsernameEdit


func _ready() -> void:
	if "--server" in OS.get_cmdline_args():
		visible = false
	
	# Already online, no need for ConnectUI
	if get_multiplayer_authority() != 1:
		visible = false
	
	if game_client:
		game_client.multiplayer_api.connected_to_server.connect(on_connected_to_server)


func on_connected_to_server():
	visible = false

func _on_join_button_pressed() -> void:
	var server_address := server_ip_edit.text
	var username := username_edit.text
	game_client.init(server_address, username)
