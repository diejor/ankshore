extends Marker2D

@export_file var myoso_scene: String


func _ready() -> void:
	var myoso_packed: PackedScene = load(myoso_scene)
	var myoso: Node2D = myoso_packed.instantiate()
	myoso.position = global_position
	get_parent().add_child.call_deferred(myoso)
