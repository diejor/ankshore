class_name baseBuff extends Resource
#var health := 500
#var damageStat := 10
#var will := 100 
#var defense := 50
#var blockingDefense := 70
#var courage := 50 
enum Stats{
	HEALTH,
	DAMAGESTAT,
	WILL,
	DEFENSE,
	BLOCKINGDEFENSE,
	COURAGE,
}
var turnStatus
var baseFlat = 15
var check: Stats = Stats.HEALTH
func specificStat() -> Stats:
	
	return check
func flatBuff() -> int:
	
	return baseFlat
	
#killing myself
#??
func turnStatusCheck() -> void:
	pass
func apply(stats: charStats) -> void:
	pass

func revert(stats: charStats) -> void:
	pass
