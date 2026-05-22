class_name DefenseInput extends RefCounted

## Defender reaction sample for one beat or ender.
##
## Produced by the defender's [TeamController] in response to
## [signal TeamState.defense_window_opened] /
## [signal TeamState.parry_window_opened], and consumed by
## [AttackStringResolver] via [signal TeamState.defense_window_closed].
## The struct reports what the defender did, not whether it succeeded -
## the resolver scores it against the active [AttackBeat].

enum Kind { NONE, BLOCK, PARRY }

## What the defender attempted.
var kind: Kind = Kind.NONE

## The vertical direction component of a [constant Kind.BLOCK]. Ignored
## when [member kind] is not [constant Kind.BLOCK].
var direction: AttackBeat.Direction = AttackBeat.Direction.OVERHEAD

## The horizontal component of a [constant Kind.BLOCK].
var side: AttackBeat.StrikeSide = AttackBeat.StrikeSide.FRONT


static func none() -> DefenseInput:
	return DefenseInput.new()


static func block(
	dir: AttackBeat.Direction, s: AttackBeat.StrikeSide
) -> DefenseInput:
	var d := DefenseInput.new()
	d.kind = Kind.BLOCK
	d.direction = dir
	d.side = s
	return d


static func parry() -> DefenseInput:
	var d := DefenseInput.new()
	d.kind = Kind.PARRY
	return d


## True when this input matches the given beat's mix.
func matches_beat(beat: AttackBeat) -> bool:
	if kind != Kind.BLOCK:
		return false
	return direction == beat.direction and side == beat.side
