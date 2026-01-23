extends Node

@onready var transition_anim: AnimationPlayer = Client.scene_manager.get_node("%TransitionAnim")
@onready var transition_progress: TextureProgressBar = Client.scene_manager.get_node("%TransitionProgress")


func teleport(
	username: String, 
	from_scene_name: String, 
	tp_path: String) -> void:
	Client.scene_manager.request_teleport.rpc_id(
		MultiplayerPeer.TARGET_PEER_SERVER,
		username,
		from_scene_name,
		tp_path
	)

func connect_player(client_data: Dictionary) -> void:
	Client.scene_manager.request_connect_player.rpc_id(
		MultiplayerPeer.TARGET_PEER_SERVER, 
		client_data
	)
	
	get_tree().unload_current_scene.call_deferred()
	
