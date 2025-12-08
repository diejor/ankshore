extends Node

func _ready() -> void:
	assert(
		owner,
		"Component owner doesn't exists. Probably because this node 
			was added at runitme.",
	)
