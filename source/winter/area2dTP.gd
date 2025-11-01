extends Area2D
@export var areaTest1 : PackedScene
@export var playerMyoso : PackedScene
@onready var myoso = %Myoso
func _on_area_2d_body_entered(_body: Node2D) -> void:
	
	
	myoso.reparent.call_deferred(MyosoManager)
	
	get_tree().change_scene_to_packed.call_deferred(areaTest1)
	await get_tree().scene_changed
	spawnMyoso.call_deferred()
	
	pass # Replace with function body.
	
func spawnMyoso() -> void:
	MyosoManager.get_child(0).reparent(get_tree().root.get_node(^"areaTest1Parent"))
	pass
