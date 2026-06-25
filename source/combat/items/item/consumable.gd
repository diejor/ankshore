class_name consumable extends item

func _init() -> void:
	return


func use_item(actor: Character) ->void:
	
	if amount >0:
		super.use_item(actor)
		amount -= 1
