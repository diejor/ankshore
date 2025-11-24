extends Control

@onready var username_label: RichTextLabel = %UsernameLabel

func _ready() -> void:
	username_label.text = Client.username
