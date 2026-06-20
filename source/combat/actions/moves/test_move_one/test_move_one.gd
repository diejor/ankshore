class_name TestMoveOne extends CombatAction
## testing example one



func _init() -> void:
	will_cost = 20
	

func resolve(actor: Character, target: Character) -> void:
	super.resolve(actor, target)
	var status: status_effect = damage_up_buff.new()
	actor.add_status_effect(status)
	print("hello test move One")
