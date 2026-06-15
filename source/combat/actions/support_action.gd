class_name SupportAction extends CharacterAction

## Concrete action representing a defensive or supportive skill.
##
## Standardizes heal and buff application across a target list.


## Executes healing or support modifications on targets.
func resolve(
	_actor: Character,
	_targets: Array[Character],
	_ctx: PhaseContext
) -> void:
	pass
