class_name LevelSynchronizer
extends MultiplayerSynchronizer

@onready var players: Node2D = %Players

@export var connected_clients: Dictionary[int, bool]:
	get:
		return connected_clients
	set(clients):
		connected_clients = clients
		update_clients.call_deferred()

func _ready() -> void:
	delta_synchronized.connect(update_clients)

func update_clients() -> void:
	for client in players.get_children():
		update_client(client)

func update_client(client: Node) -> void:
	client.request_ready()
	var component: ClientComponent = client.get_node("%ClientComponent")
	component.sync.update_visibility()
	component.server_visibility.update_visibility()
