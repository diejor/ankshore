extends Resource
class_name charStats
#unsure on how to continue with levels

#Title of Char---------------------------
@export var title = "TestCharacter"
#--------------------------------------
signal health_depleted #decomissioned char
signal health_changed(health: int, max_health: int) #tells current health change

var buffsHolder: Array[baseBuff]
var stats: baseBuff.Stats = baseBuff.Stats.HEALTH

#base_ stuff-----------------------------------------------
#some characters may change max health
@export var level = 1
@export var base_max_health := 500
#damage lol
@export var base_damageStat := 10
#'stamina/mana' bar
@export var base_max_will := 100 
#defense reduces damage taken
@export var base_Defense := 50
#defense (usually heightened) when a successful block occurs. 
@export var base_blockingDefense := 70
#courage is a stat that determines how much status effect damage one takes
@export var base_courage := 50 

#current_max_ stuff------------------------------

var current_max_health := base_max_health
var current_damageStat := base_damageStat
var current_max_will := base_max_will
var current_defense := base_Defense
var current_blockingDefense := base_blockingDefense
var current_courage := base_courage 

#actual stuff----------------------------------
enum Stats{
	HEALTH,
	DAMAGESTAT,
	WILL,
	DEFENSE,
	BLOCKINGDEFENSE,
	COURAGE,
}

#initial values 
var health := current_max_health #HEALTH
var damageStat := current_damageStat #1
var will := current_max_will 
var defense := current_defense 
var blockingDefense := current_blockingDefense
var courage := current_courage 




#assigning functions----------------------------
func _init()-> void:
	setup_Stats.call_deferred

func setup_Stats() -> void:
	health = base_max_health
	

func set_health(newHealth: int) -> void:
	recalculateStats()
	health = newHealth
	

func statsBuffer() -> void:
	pass

func statsDebuffer() -> void:
	pass
#used after buffs, debuffs, whenever necessary



func recalculateStats()-> void:
	for buff in buffsHolder:
		print("hello")
		#if(buff.turn = 0){
			#
		#}
		buff.get
	
	pass






#other/gameplay functions (?)---------------------------
func change_health(changeValue: int) -> void: #damage is negative | health is positive
	#will figure out a way to apply defense or whatever later
	health += changeValue
	if health > current_max_health:
		health = current_max_health
	elif health < 0:
		health_depleted.emit()
	health_changed.emit(health, current_max_health)

#getters
func getDamageStat() -> int:
	return damageStat


#each attack within an attack string will read if the attack has been blocked or not
func damageTaken(dmg: int, blocked: bool) -> int:
	if !blocked:
		var dmgCalc = dmg * (100/(100+defense)) # im using league of legends armor calculation lol
		return dmg
	else:
		#this is blocking dmg calculation for now
		var dmgCalc = dmg * (blockingDefense/100)
		if dmgCalc > 0:
			return dmgCalc
		return 0
