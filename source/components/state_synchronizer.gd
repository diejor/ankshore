class_name StateSynchronizer
extends MultiplayerSynchronizer

@export_group("Replicated")
var username_label: RichTextLabel:
	get: return %ClientHUD/%UsernameLabel
@export var username: String = "":
	set(user):
		username = user
		username_label.text = user

	
