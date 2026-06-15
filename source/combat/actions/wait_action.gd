class_name WaitAction extends CharacterAction

## Default self-targeted action that spends the turn without effects.


func _init() -> void:
	targets_self = true
	name = "Wait"


## Leaves [param actor] unchanged.
func resolve(_actor: Character, _target: Character) -> void:
	pass
