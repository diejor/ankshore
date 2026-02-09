extends Button
@export var winterScene: PackedScene
@export_file var network_scene: String

@onready var play_game: Label = $PlayGame
@onready var connecting: Label = $Loading
@onready var username_edit: LineEdit = %UsernameEdit

func _ready() -> void:
	#disabled = true
	#flip_labels()
	pass
	

func flip_labels() -> void:
	play_game.visible = not play_game.visible
	connecting.visible = not play_game.visible


func _on_pressed() -> void:
	flip_labels()
	
	get_tree().change_scene_to_file(network_scene)

func _on_connected_to_server() -> void:
	disabled = false
	flip_labels()
