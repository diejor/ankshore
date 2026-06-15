extends Button

@onready var username_edit: UsernameEdit = %UsernameEdit
@onready var client: MultiplayerTree = %Client
@onready var menu_ui: Control = %MenuUI
@onready var game_ui: Control = %GameUI

@export_custom(0, "SceneNodePath:MultiplayerEntity")
var spawner_component: SceneNodePath

@onready var ctx := Netw.ctx(client)

func _ready() -> void:
	ctx.tree.session_entered.connect(_on_connected_to_server)


func _on_connected_to_server() -> void:
	game_ui.visible = false

func _on_pressed() -> void:
	disabled = true
	var join_payload := JoinPayload.new()
	join_payload.username = username_edit.username
	
	var policy := EntitySpawnPolicy.from_scene_node_path(spawner_component)
	join_payload.spawn = policy.to_dict()

	var target := JoinTarget.new()
	target.backend = LocalLoopbackBackend.new()
	client.join_or_host(target, join_payload)
