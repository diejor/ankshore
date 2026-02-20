extends Resource
class_name charStats
#unsure on how to continue with levels


signal health_depleted #decomissioned char
signal health_changed(health: int, max_health: int) #tells current health change

#base_ stuff-----------------------------------------------
#some characters may change max health
@export var level = 1
@export var base_max_health := 500
#damage lol
@export var base_damageStat := 10
#'stamina/mana' bar
@export var base_will := 100 
#defense reduces damage taken
@export var base_Defense := 50
#defense (usually heightened) when a successful block occurs. 
@export var base_blockingDefense := 70
#courage is a stat that determines how much status effect damage one takes
@export var base_courage := 50 

#current_max_ stuff------------------------------

var current_max_health := 500
var current_damageStat := 10
var current_max_will := 100 
var current_defense := 50
var current_blockingDefense := 70
var current_courage := 50 

#actual stuff----------------------------------
var health := 500
var damageStat := 10
var will := 100 
var defense := 50
var blockingDefense := 70
var courage := 50 

#health
#damageStat
#will
#defense 
#blockingDefense
#courage


#assigning functions----------------------------
func _init()-> void:
	setup_Stats.call_deferred

func setup_Stats() -> void:
	health = base_max_health
	

func set_health(newHealth: int) -> void:
	recalculateStats()
	health = newHealth
	


#used after buffs, debuffs, whenever necessary
func recalculateStats()-> void:
	
	
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
