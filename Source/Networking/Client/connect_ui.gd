extends CanvasLayer

@onready var server_ip_edit: TextEdit = %ServerIpEdit
@onready var username_edit: TextEdit = %UsernameEdit
var _hide_on_connect := false

func _ready() -> void:
	if "--server" in OS.get_cmdline_args():
		visible = false

func on_connected_to_server() -> void:
	if _hide_on_connect:
		visible = false

func _on_join_button_pressed() -> void:
	var server_address := server_ip_edit.text
	var username := username_edit.text
	_hide_on_connect = true
	var err: Error = Client.connect_client(server_address, username)
	if err != OK:
		push_warning("Connection failed: %s" % error_string(err))
		_hide_on_connect = false
