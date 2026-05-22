class_name AIController extends TeamController

## Placeholder AI - does nothing yet.
##
## Returns an empty plan so the enemy team skips its turn each round
## while the planning/resolution machinery exercises end-to-end. Swap
## the body of [method plan_turn] when adding a real policy.


func plan_turn(_ctx: PhaseContext) -> Array[CommittedAction]:
	return []
