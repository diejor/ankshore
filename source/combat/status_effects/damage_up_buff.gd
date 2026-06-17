class_name damage_up_buff extends status_buff

## Concrete status effect that increases a character's physical damage.
##
## Standard status effect that defaults to modifying the damage stat.


func _init() -> void:
	status_name = "Damage Up"
	type = StatType.DAMAGE
	flat_value = 15
	duration = 3
	
