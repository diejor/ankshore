class_name status_effect extends Resource

## Base resource representing a buff or status effect in combat.
##
## Standardizes modifiers that affect character attributes.


enum StatType {
	HEALTH,
	DAMAGE,
	WILL,
	DEFENSE,
	BLOCKING_DEFENSE,
	COURAGE,
	SPEED,
}

@export var status_name: String = "Status Effect Base"

## The stat that is modified by this status effect.
@export var type: StatType = StatType.HEALTH

##
var core_change_types: Dictionary[StatType, int]

##
@export var extra_change_types: Dictionary[extra_stat, int]

## Flat amount added to the base stat.
@export var flat_value: int = 15

## Number of turns this effect remains active.
@export var duration: int = 3

func _init() ->void:
	return

## changes the core stats
func core_stat_changes() -> Dictionary[StatType, int]:
	return core_change_types
	
func extra_stat_changes() -> Dictionary[extra_stat, int]:
	return extra_change_types
## Called on each turn tick to decrement the duration of the buff. Any extra mechanics can also be placed here
## in children classes
func tick() -> void:
	if duration > 0:
		duration -= 1
