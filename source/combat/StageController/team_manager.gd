class_name TeamManager
extends Node

@export var team: Team
@onready var turn_manager: turnManager = %TurnManager

var ongoing_turn: Turn

enum Team {
	Ally,
	Enemy
}


func _ready() -> void:
	turn_manager.turnStart.connect(_on_turn_start)

func is_test_character(node: Node) -> bool:
	return node is testCharacter

func get_test_characters() -> Array[testCharacter]:
	var character_children: Array[testCharacter]
	character_children.assign(get_children().filter(is_test_character))
	return character_children

func _on_turn_start(team_playing: Team) -> void:
	var turn := Turn.new()
	turn.team_playing = team_playing
	
	# if not the same team return
	if team_playing != team:
		return
	
	# iterate through all the test characters inside a team to build actionsaaaa
	for character in get_test_characters():
		var action := await character.start_action()
		turn.actions.append(action)
	
	print("Actions from %s: %s." % [team_playing, turn.actions])
	
	# at the end execute the actions
	for action in turn.actions:
		action.execute()
