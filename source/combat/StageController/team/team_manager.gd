class_name TeamManager extends Node2D

## Represents one side in a combat encounter.
##
## [br][br]
## Tracks [member tracked_characters] as children are added and
## places them into [member slots]. On [signal TurnManager.turn_started],
## each character submits an action sequentially; then
## [method TurnManager.end_turn] closes the turn.

enum Team {
	Ally,
	Enemy
}

## Emitted once all characters on this team have acted.
signal actions_finished(actions: Array[charAction])

## Which side this team belongs to.
@export var team: Team:
	set(value):
		team = value
		if team == Team.Enemy:
			mirror_team.call_deferred(-1)
		else:
			mirror_team.call_deferred(1)

## Slots used to position characters on the field.
@export var slots: Array[SelectionSlot]

## The [TurnManager] resolved by unique name from the scene root.
@onready var turn_manager: TurnManager:
	get: return get_node_or_null("%TurnManager")

## Display name of [member team].
var team_str: String:
	get:
		return Team.find_key(team)

## Characters registered to this team.
var tracked_characters: Array[testCharacter]

func _init() -> void:
	child_entered_tree.connect(_on_child_entered)

## Mirrors all [code]mirror[/code]-group descendants by
## [param mirror] on the x axis.
func mirror_team(mirror: int) -> void:
	for node in get_tree().get_nodes_in_group("mirror"):
		if is_ancestor_of(node) or node == self:
			@warning_ignore("unsafe_property_access")
			node.scale.x *= mirror

## Returns the opposing [TeamManager] via [member turn_manager].
func get_other_team() -> TeamManager:
	return turn_manager.get_other_team(self)

# activates on turn start, collects an action from each character,
# then executes them in order
func _on_turn_started(team_playing: TeamManager) -> void:
	if team_playing != self:
		return
	assert(
		not tracked_characters.is_empty(),
		"Team '%s' has no characters." % name
	)
	var actions: Array[charAction]
	for character in tracked_characters:
		var action := await character.start_action()
		actions.append(action)
	for action in actions:
		action.execute()
	actions_finished.emit(actions)
	turn_manager.end_turn()

# places the character into the first available slot
func _organize_character(character: testCharacter) -> void:
	if Engine.is_editor_hint():
		return
	for slot in slots:
		if not slot.selected:
			slot.selected = character
			return

# registers any testCharacter child and assigns it a slot
func _on_child_entered(node: Node) -> void:
	if Engine.is_editor_hint():
		return
	if node is testCharacter:
		tracked_characters.append(node)
		_organize_character(node as testCharacter)
