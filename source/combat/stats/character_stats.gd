class_name CharacterStats extends Resource

## Holds and recalculates attributes for a combat participant.
##
## Standardizes character growth stats and active buff/debuff modifications.

signal health_depleted
signal health_changed(current: int, max_val: int)
signal level_up(level: int)

## Emitted by [method change_will] after [member will] is adjusted.
signal will_changed(current: int, max_val: int)

## Emitted by [method change_courage] after [member courage] is adjusted.
signal courage_changed(current: int, max_val: int)

## Emitted after [member active_buffs] is mutated. UI views bind to this
## to re-render buff/debuff icons. Callers that mutate [member active_buffs]
## directly should emit this themselves until proper add/remove helpers
## exist.
@warning_ignore("unused_signal")
signal buffs_changed(buffs: Array)

## Custom name or identifier for the character.
@export var title: String = "TestCharacter"

## Leveling attributes
@export var level: int = 1
var levelCapEXP: int = 100 # level cap exp, increases ex
var currentEXP: int = 0

## Level One Basic Stats
var oneMaxHealth: int = 500
var oneDamage: int = 10
var oneMax_will: int = 100
var oneDefense: int = 50
var oneBlocking_defense: int = 70
var oneCourage: int = 50
var oneSpeed: int = 10

## Base attributes, increases with levels
@export var base_max_health: int = oneMaxHealth
@export var base_damage: int = oneDamage
@export var base_max_will: int = oneMax_will
@export var base_defense: int = oneDefense
@export var base_blocking_defense: int = oneBlocking_defense
@export var base_courage: int = oneCourage
@export var base_speed: int = oneSpeed


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
var active_buffs: Array[status_effect] = []







#functions

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
			status_effect.StatType.HEALTH:
				max_health += buff.flat_value
			status_effect.StatType.DAMAGE:
				damage += buff.flat_value
			status_effect.StatType.WILL:
				max_will += buff.flat_value
			status_effect.StatType.DEFENSE:
				defense += buff.flat_value
			status_effect.StatType.BLOCKING_DEFENSE:
				blocking_defense += buff.flat_value
			status_effect.StatType.COURAGE:
				courage += buff.flat_value
			status_effect.StatType.SPEED:
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


## Adjusts active will by [param change_value] (cost is negative). Will
## is clamped to [code][0, max_will][/code].
func change_will(change_value: int) -> void:
	will = clampi(will + change_value, 0, max_will)
	will_changed.emit(will, max_will)


## Adjusts active courage by [param change_value]. Courage is clamped to
## [code][0, max(base_courage, courage)][/code] - growth uses the
## recalculated cap from [method recalculate_stats].
func change_courage(change_value: int) -> void:
	@warning_ignore("unsafe_call_argument") # ???
	courage = clampi(courage + change_value, 0, max(courage, base_courage))
	courage_changed.emit(courage, base_courage)

## Calculates gained experience after a battle or interaction
func gainExperience(gainedEXP: int) -> void:
	if gainedEXP+currentEXP >= levelCapEXP:
		level += 1
		changeLevel(level)
		currentEXP = (gainedEXP + currentEXP) - levelCapEXP # recycles extra exp for next level
	else:
		currentEXP = gainedEXP

##Procs recalculateStats, creates new exp cap for new level using exponential(?) equation
func changeLevel(lvlChange:int) -> void:
	levelCapEXP += 1000 #temporary
	base_max_health = oneMaxHealth + (lvlChange*20)
	base_damage += oneMaxHealth + (lvlChange*20)
	base_max_will += oneMaxHealth + (lvlChange*20)
	base_defense += oneMaxHealth + (lvlChange*20)
	base_blocking_defense += oneMaxHealth + (lvlChange*20)
	base_courage += oneMaxHealth + (lvlChange*20)
	base_speed += oneMaxHealth + (lvlChange*20)
	recalculate_stats()
	level_up.emit(lvlChange)
	return

## Applies incoming physical damage after accounting for blocking/armor.
func damage_taken(dmg: int, blocked: bool) -> int:
	if not blocked:
		# Using standard armor damage reduction logic.
		@warning_ignore("integer_division")
		var damage_after_armor := dmg * 100 / (100 + defense)
		@warning_ignore("unsafe_call_argument")
		return int(max(0, damage_after_armor))
	else:
		# Using blocking defense scaling percentage reduction.
		@warning_ignore("integer_division")
		var dmg_reduction := dmg * blocking_defense / 100
		var remaining_dmg := dmg - dmg_reduction
		@warning_ignore("unsafe_call_argument")
		return int(max(0, remaining_dmg))
