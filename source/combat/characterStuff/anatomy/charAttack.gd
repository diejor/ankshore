extends charAction
class_name charAttack

enum atkState {
	OVER_LOW, 
	LEFT_RIGHT
	}

var directAtk = atkState.OVER_LOW
var baseAttackDmg = 10

#var directionAtk = 0; # 0 = overhead/low || 1 = left/right


func recalculateStats(buff: int):
	baseAttackDmg += buff
	pass

func attack() -> int:
	return baseAttackDmg
func effects() -> int:
	
	return 5
