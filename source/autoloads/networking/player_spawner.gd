class_name PlayerSpawner
extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = spawn_player


func spawn_player(player_data: Dictionary) -> Node2D:
	var client_data: Dictionary = player_data.client_data
	var player: Node = ClientComponent.instantiate(client_data)
	

	var save_component: SaveComponent = player.get_node_or_null("%SaveComponent")
	if save_component:
		save_component.deserialize_scene(player_data.save as PackedByteArray)	
	
	return player
