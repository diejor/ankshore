extends Camera2D

@onready var _ctx := Netw.ctx(self)

func _ready() -> void:
	var is_template := _ctx.entity.is_template
	var is_dedicated := _ctx.tree.get_role() == MultiplayerTree.Role.DEDICATED_SERVER
	if not is_multiplayer_authority() or is_template or is_dedicated:
		queue_free()
	else:
		reset_smoothing()
		make_current()
