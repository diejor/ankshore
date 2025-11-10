extends Control

func _ready() -> void:
	visible = false

func on_player_spawn_data(player_data: Dictionary):
	scene_ready.call_deferred(player_data)

func scene_ready(player_data: Dictionary):
	%UsernameLabel.text = player_data.username
	%UIDLabel.text = "[color=gray]%s[/color]" % player_data.peer_id
	visible = true
