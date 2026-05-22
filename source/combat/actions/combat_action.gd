class_name CombatAction extends Node

## Base class representing an executable action during a turn.
##
## [br][br]
## All specific actions (Attack, Support, Item) inherit from this class.

## The entity initiating this action.
var attacker: Character

## List of target entities for this action.
@export var targets: Array[Character] = []


## Executable entry point for the action. Must be overridden by subclasses.
func execute() -> void:
	pass
