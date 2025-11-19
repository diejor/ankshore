extends Control

@onready var username_label: RichTextLabel = %UsernameLabel
@onready var uid_label: RichTextLabel = %UIDLabel

func _ready() -> void:
	visible = false

func _on_spawn(player_data: Dictionary) -> void:
	username_label.text = player_data.username
	uid_label.text = "[color=gray]%s[/color]" % player_data.peer_id
	visible = true
