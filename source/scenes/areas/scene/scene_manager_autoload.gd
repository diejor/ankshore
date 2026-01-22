extends Node

@onready var transition_anim: AnimationPlayer = Client.scene_manager.get_node("%TransitionAnim")
@onready var transition_progress: TextureProgressBar = Client.scene_manager.get_node("%TransitionProgress")
@onready var tp_canvas_layer: CanvasLayer =  Client.scene_manager.get_node("%TPCanvasLayer")

func _ready() -> void:
	tp_canvas_layer.set_deferred("visible", false)

func teleport(
	username: String, 
	from_scene_name: String, 
	tp_path: String) -> void:
	transition_anim.play("show")
	
	Client.scene_manager.request_teleport.rpc_id(
		MultiplayerPeer.TARGET_PEER_SERVER,
		username,
		from_scene_name,
		tp_path
	)

func connect_player(client_data: Dictionary) -> void:
	transition_anim.play("show")
	await transition_anim.animation_finished
	
	Client.scene_manager.request_connect_player.rpc_id(
		MultiplayerPeer.TARGET_PEER_SERVER, 
		client_data
	)
	
	get_tree().unload_current_scene.call_deferred()
	
