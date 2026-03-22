class_name TeamManager
extends Node

enum Team {
	Ally,
	Enemy
}

signal actions_finished(actions: Array[charAction])

@export var team: Team
@export var slots: Array[SelectionSlot]

@onready var turn_manager: TurnManager = %TurnManager

var team_str: String:
	get:
		return Team.find_key(team)

var tracked_characters: Array[testCharacter]

func _init() -> void:
	child_entered_tree.connect(_on_child_entered)

func _organize_character(character: testCharacter) -> void:
	for slot in slots:
		if not slot.selected:
			slot.selected = character
			return

func _on_child_entered(node: Node) -> void:
	if node is testCharacter:
		tracked_characters.append(node)
		_organize_character(node as testCharacter)


func _on_turn_start(team_playing: TeamManager) -> void:
	# if not the same team return
	if team_playing != self:
		return
	
	var actions: Array[charAction]
	# iterate through all the test characters inside a team to build actions
	for character in tracked_characters:
		var action := await character.start_action()
		actions.append(action)
	
	print("Actions from %s: %s." % [team_playing.name, actions])
	
	# at the end execute the actions
	for action in actions:
		action.execute()

	actions_finished.emit(actions)
	turn_manager.turn_ended.emit(team_playing)


func _on_turn_ended(_team_playing: TeamManager) -> void:
	pass
