extends Button

@onready var play_game: Label = $PlayGame
@onready var username_edit: LineEdit = %UsernameEdit
@onready var client: MultiplayerTree = %Client
@onready var menu_ui: Control = %MenuUI


@onready var _ctx := Netw.ctx(client)
@export var join_payload: JoinPayload

var username: String:
	get:
		if username.is_empty():
			var candidate := OS.get_environment("USERNAME")
			if candidate.is_empty():
				candidate = "player"
			username = candidate
		return username

func _ready() -> void:
	_ctx.tree.connected_to_server.connect(_on_connected_to_server)

func _on_connected_to_server() -> void:
	menu_ui.visible = false

func _on_pressed() -> void:
	disabled = true
	join_payload.username = username
	client.connect_player(join_payload)
