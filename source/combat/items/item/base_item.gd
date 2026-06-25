class_name item extends Resource
## items usuable or readable by the player 

##name will serve as ID for item (for now)
@export var item_name: String = "Base Item"

@export var item_description: String = "A basic item that does nothing"

@export var weight: int

@export var amount: int = 0

@export var texture: Texture2D

##whenever a character uses an item in the OVERWORLD
func use_item(actor: Character) -> void:
	if amount > 0:
		print("using item!")
	return
