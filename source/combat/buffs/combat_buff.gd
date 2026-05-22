class_name CombatBuff extends Resource

## Base resource representing a buff or status effect in combat.
##
## [br][br]
## Standardizes modifiers that affect character attributes.

enum StatType {
	HEALTH,
	DAMAGE,
	WILL,
	DEFENSE,
	BLOCKING_DEFENSE,
	COURAGE
}

## The stat that is modified by this status effect.
@export var type: StatType = StatType.HEALTH

## Flat amount added to the base stat.
@export var flat_value: int = 15

## Number of turns this effect remains active.
@export var duration: int = 3


# Called on each turn tick to decrement the duration of the buff.
func tick() -> void:
	if duration > 0:
		duration -= 1
