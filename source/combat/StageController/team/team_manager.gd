class_name TeamManager
extends Node2D

enum Team {
	Ally,
	Enemy
}

signal actions_finished(actions: Array[charAction])

@export var team: Team:
	set(value):
		team = value
		if team == Team.Enemy:
			mirror_team.call_deferred(-1)
		else:
			mirror_team.call_deferred(1)

@export var slots: Array[SelectionSlot]

@onready var turn_manager: TurnManager:
	get: return get_node_or_null("%TurnManager")

var team_str: String:
	get:
		return Team.find_key(team)

var tracked_characters: Array[testCharacter]

func _init() -> void:
	if Engine.is_editor_hint():
		return
	
	child_entered_tree.connect(_on_child_entered)

func mirror_team(mirror: int) -> void:
	for to_mirror in get_tree().get_nodes_in_group("mirror"):
		if is_ancestor_of(to_mirror) or to_mirror == self:
			@warning_ignore("unsafe_property_access")
			to_mirror.scale.x *= mirror

func get_other_team() -> TeamManager:
	return turn_manager.get_other_team(self)

func _organize_character(character: testCharacter) -> void:
	if Engine.is_editor_hint():
		return
	
	for slot in slots:
		if not slot.selected:
			slot.selected = character
			return

func _on_child_entered(node: Node) -> void:
	if Engine.is_editor_hint():
		return
	
	if node is testCharacter:
		tracked_characters.append(node)
		_organize_character(node as testCharacter)


func _on_turn_start(team_playing: TeamManager) -> void:
	assert(not tracked_characters.is_empty(), "Team is playing with no players.")
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
	#turn_manager.turn_ended.emit(team_playing)


func _on_turn_ended(_team_playing: TeamManager) -> void:
	pass
