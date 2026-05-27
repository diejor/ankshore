class_name ItemAction extends CombatAction

## Concrete action representing the usage of a consumable inventory item.
##
## Standardizes target resolution and consumable usage checks.


## Triggers consumable item application logic on targets.
func execute(_actor: Character, _targets: Array[Character]) -> void:
	pass
