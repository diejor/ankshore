class_name SupportAction extends CombatAction

## Concrete action representing a defensive or supportive skill.
##
## Standardizes heal and buff application and targets list.


## Executes healing or support modifications on targets.
func execute(_actor: Character, _targets: Array[Character]) -> void:
	pass
