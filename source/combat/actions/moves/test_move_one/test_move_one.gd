class_name TestMoveOne extends CombatAction
## testing example one



func _init() -> void:
	will_cost = 20
	

func resolve(actor: Character, target: Character) -> void:
	super.resolve(actor, target)
	print("hello test move One")
