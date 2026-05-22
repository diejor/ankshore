class_name AttackAction extends CombatAction

## Concrete action representing a physical attack.
##
## [br][br]
## Standardizes damage scaling calculations and execution rules.

enum AttackDirection {
	OVER_LOW,
	LEFT_RIGHT
}

## Direct of attack (overhead/low or left/right combo style).
@export var direction: AttackDirection = AttackDirection.OVER_LOW

## Baseline damage of the attack before stat scaling.
@export var base_damage: int = 10


## Evaluates damage based on attacker's damage stat and applies it to targets.
func execute() -> void:
	if not attacker or not attacker.stats:
		return
	
	var damage_power := base_damage + attacker.stats.damage
	
	for target in targets:
		if target and target.stats:
			# Check blocking chance (could be expanded later, default to false).
			var is_blocked := false
			var actual_dmg := target.stats.damage_taken(damage_power, is_blocked)
			target.take_dmg(actual_dmg, is_blocked)
