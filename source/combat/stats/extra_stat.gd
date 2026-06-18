class_name extra_stat extends Resource
var extra_stat_num:float = 0

func reset_to_zero() -> void:
	extra_stat_num = 0
	
func change_stat(change: float) -> void:
	extra_stat_num += change
	
