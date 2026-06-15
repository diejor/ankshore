class_name ItemAction extends CharacterAction

## Concrete action representing the usage of a consumable inventory item.
##
## Standardizes target resolution and consumable usage checks.


## Triggers consumable item application logic on targets.
func resolve(
	_actor: Character,
	_targets: Array[Character],
	_ctx: PhaseContext
) -> void:
	pass
