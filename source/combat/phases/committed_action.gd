class_name CommittedAction extends RefCounted

## Plain-data result of one character's planning sub-tree.
##
## A [PlanningPhase] produces an [code]Array[CommittedAction][/code]
## that [ResolutionPhase] sorts by [member speed_roll] and executes by
## binding the actor/targets into the underlying [CombatAction] node
## via [method to_runtime_action].

var actor: Character
var move: CombatAction
var targets: Array[Character]
var speed_roll: int = 0


func _init(
	p_actor: Character,
	p_move: CombatAction,
	p_targets: Array[Character]
) -> void:
	actor = p_actor
	move = p_move
	targets = p_targets


## Binds runtime fields onto [member move] and returns it for execution.
func to_runtime_action() -> CombatAction:
	move.attacker = actor
	move.targets = targets
	return move
