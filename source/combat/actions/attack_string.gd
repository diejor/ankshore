class_name AttackString extends Resource

## A player-built sequence of [AttackBeat]s capped by an attack
## [CombatAction].
##
## Not a move itself - the attacker picks the [member move] during
## planning, then assembles [member beats] interactively before the string
## commits. [AttackStringResolver] plays the beats in order, then resolves
## the move. Constructed at runtime; never authored as a [code].tres[/code].

## Ordered beats played in turn against the defender.
@export var beats: Array[AttackBeat] = []

## The attack move appended after the beats. Set at runtime, not
## serialized. Resolves via [method CombatAction.resolve].
var move: CombatAction = null
