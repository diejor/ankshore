extends Resource
class_name baseChar

#some characters may change max health
@export var max_health := 500
@export var health := 500
#damage lol
@export var baseDamage := 10
#'stamina/mana' bar
@export var will := 100 
#defense reduces damage taken
@export var baseDefense := 50
@export var blockingDefense := 70
#courage is a stat that determines how much status effect damage one takes
@export var courage := 50 


#each attack within an attack string will read if the attack has been blocked or not
func damageTaken(dmg: int, blocked: bool) -> int:
	
	
	
	return 0
