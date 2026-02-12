extends charAction
class_name charAttack

var baseAttackDmg = 10

func recalculateStats(buff: int):
	baseAttackDmg += buff
	pass

func attack() -> int:
	return baseAttackDmg
func effects() -> int:
	
	return 5
