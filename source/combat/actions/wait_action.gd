class_name WaitAction extends CombatAction

## Default self-targeted action that spends the turn without effects.


func _init() -> void:
	targets_self = true
	name = "Wait"


## Leaves [param actor] unchanged.
func execute(_actor: Character, _targets: Array[Character]) -> void:
	pass


## Completes immediately; idle animations may loop and never finish.
func execute_async(
	actor: Character,
	targets: Array[Character],
	_ctx: PhaseContext
) -> void:
	execute(actor, targets)
