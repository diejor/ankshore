@abstract class_name TeamController extends Node

## Drives a [TeamManager]'s [TeamState] from some decision source.
##
## Subclasses pick a strategy: [PlayerController] reads [InputEvent]s,
## [AIController] computes a policy, future variants might read from a
## network socket. All of them write to the same [TeamState] via its
## mutation methods - they are the [b]controller[/b] in the MVC sense
## while [TeamState] is the model.

## The team this controller is bound to. The controller mutates the
## state exposed on [member TeamManager.state].
@export var team: TeamManager

## Convenience accessor for the bound [TeamState]. Returns
## [code]null[/code] when [member team] is unset.
var state: TeamState:
	get:
		return team.state if team else null
