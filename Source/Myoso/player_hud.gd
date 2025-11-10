extends Control

func _ready() -> void:
	visible = false

func _on_spawn(player_data: Dictionary) -> void:
	%UsernameLabel.text = player_data.username
	%UIDLabel.text = "[color=gray]%s[/color]" % player_data.peer_id
	visible = true
