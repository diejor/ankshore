extends Control

@onready var username_label: RichTextLabel = %UsernameLabel
@onready var uid_label: RichTextLabel = %UIDLabel

func _ready() -> void:
	visible = false

func _on_spawn() -> void:
	visible = true
