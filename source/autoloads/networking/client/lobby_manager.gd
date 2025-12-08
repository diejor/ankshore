class_name LobbyManager
extends Node

const WINTER = preload("uid://xkil2cmplfcd")
const AREA_TEST_1 = preload("uid://dta1ona6odgmr")


@rpc("any_peer", "call_remote", "reliable")
func connect_player(client_data: Dictionary) -> void:
	var player: Node = ClientComponent.instantiate(client_data)
	var save_component: SaveComponent = player.get_node("%SaveComponent")
	var tp_component: TPComponent = player.get_node("%TPComponent")
	
	var load_error: Error = save_component.load_state()
	assert(load_error == OK or load_error == ERR_FILE_NOT_FOUND, 
		"Something failed while trying to load player. 
		Error: %s." % error_string(load_error))
	
	var current_scene: String = tp_component.current_scene
	if current_scene.is_empty():
		current_scene = AREA_TEST_1.resource_path
		
	change_scene.rpc_id(client_data.peer_id as int, current_scene)


@rpc("any_peer", "call_remote", "reliable")
func change_scene(player_current_scene: String) -> void:
	get_tree().change_scene_to_file(player_current_scene)
