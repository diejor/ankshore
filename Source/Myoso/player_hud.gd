extends Control

var visible_mask: bool

func _ready() -> void:
	visible = false
	if visible_mask:
		visible = visible_mask

func on_player_data(player_data: Dictionary):
	%UsernameLabel.text = player_data.username
	%UIDLabel.text = "[color=gray]%s[/color]" % player_data.peer_id
	visible_mask = true
