class_name CharacterStats extends Resource

## Holds and recalculates attributes for a combat participant.
##
## Standardizes character growth stats and active buff/debuff modifications.

signal health_depleted
signal health_changed(current: int, max_val: int)

## Custom name or identifier for the character.
@export var title: String = "TestCharacter"

## Base attributes
@export var level: int = 1
@export var base_max_health: int = 500
@export var base_damage: int = 10
@export var base_max_will: int = 100
@export var base_defense: int = 50
@export var base_blocking_defense: int = 70
@export var base_courage: int = 50
@export var base_speed: int = 10

## Current status attributes (recalculated with active buffs)
var max_health: int = 500
var damage: int = 10
var max_will: int = 100
var defense: int = 50
var blocking_defense: int = 70
var courage: int = 50
var speed: int = 10

## Active health and will points
var health: int = 500
var will: int = 100

## Active status effects and modifiers currently applied
var active_buffs: Array[CombatBuff] = []


func _init() -> void:
	# Defer initial state calculation.
	setup_stats.call_deferred()


## Initializes character health and will points based on baseline stats.
func setup_stats() -> void:
	recalculate_stats()
	health = max_health
	will = max_will


## Iterates through all active buffs to modify base stats.
func recalculate_stats() -> void:
	max_health = base_max_health
	damage = base_damage
	max_will = base_max_will
	defense = base_defense
	blocking_defense = base_blocking_defense
	courage = base_courage
	speed = base_speed

	for buff in active_buffs:
		match buff.type:
			CombatBuff.StatType.HEALTH:
				max_health += buff.flat_value
			CombatBuff.StatType.DAMAGE:
				damage += buff.flat_value
			CombatBuff.StatType.WILL:
				max_will += buff.flat_value
			CombatBuff.StatType.DEFENSE:
				defense += buff.flat_value
			CombatBuff.StatType.BLOCKING_DEFENSE:
				blocking_defense += buff.flat_value
			CombatBuff.StatType.COURAGE:
				courage += buff.flat_value
			CombatBuff.StatType.SPEED:
				speed += buff.flat_value


## Adjusts active health by [param change_value] (damage is negative).
func change_health(change_value: int) -> void:
	health += change_value
	if health > max_health:
		health = max_health
	elif health <= 0:
		health = 0
		health_depleted.emit()
	health_changed.emit(health, max_health)


## Applies incoming physical damage after accounting for blocking/armor.
func damage_taken(dmg: int, blocked: bool) -> int:
	if not blocked:
		# Using standard armor damage reduction logic.
		@warning_ignore("integer_division")
		var damage_after_armor := dmg * 100 / (100 + defense)
		return int(max(0, damage_after_armor))
	else:
		# Using blocking defense scaling percentage reduction.
		@warning_ignore("integer_division")
		var dmg_reduction := dmg * blocking_defense / 100
		var remaining_dmg := dmg - dmg_reduction
		return int(max(0, remaining_dmg))
