class_name AttackBeat extends Resource

## One hit inside an [AttackString].
##
## A beat is a discrete press-now-or-fail input window on the defender.
## The pair ([member direction], [member side]) tells the defender what
## to press; [member damage] applies on hit, [member chip_pct] on block.

enum Direction { OVERHEAD, LOW }
enum StrikeSide { FRONT, BEHIND }

## Vertical mix - high (overhead) or low.
@export var direction: Direction = Direction.OVERHEAD

## Horizontal mix - attacker swings from the defender's front or behind.
@export var side: StrikeSide = StrikeSide.FRONT

## Damage dealt when this beat lands unblocked.
@export var damage: int = 10

## Fraction of [member damage] dealt as chip when the beat is blocked.
@export var chip_pct: float = 0.1

## Seconds the defender has to react. The resolver may shorten this for
## later beats once the attacker is committed to the string.
@export var react_window_sec: float = 0.8


## Human-readable label for logs and UI cues.
func describe() -> String:
	return "%s %s" % [
		StrikeSide.find_key(side),
		Direction.find_key(direction),
	]
