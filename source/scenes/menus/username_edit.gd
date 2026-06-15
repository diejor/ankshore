class_name UsernameEdit
extends LineEdit

var username: String:
	get:
		if not text.is_empty():
			return text
		if username.is_empty():
			var candidate := OS.get_environment("USERNAME")
			if candidate.is_empty():
				candidate = "player"
			username = candidate
		return username

func _ready() -> void:
	placeholder_text = username
