class_name DamageUpBuff extends CombatBuff

## Concrete status effect that increases a character's physical damage.
##
## Standard status effect that defaults to modifying the damage stat.


func _init() -> void:
	type = StatType.DAMAGE
	flat_value = 15
	duration = 3
