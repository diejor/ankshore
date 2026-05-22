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
		_apply_team_layout.call_deferred()

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

# Stores original slot positions to allow idempotent layout mirroring.
var _original_slot_positions: Dictionary = {}

@onready var team_label: Label = $Label


func _init() -> void:
	child_entered_tree.connect(_on_child_entered)


func _ready() -> void:
	for slot in slots:
		_original_slot_positions[slot] = slot.position
	_apply_team_layout()


## Returns the opposing [TeamManager] via [member turn_manager].
func get_other_team() -> TeamManager:
	return turn_manager.get_other_team(self)


# Sets horizontal layout positions and text based on team assignment.
func _apply_team_layout() -> void:
	var factor := -1 if team == Team.Enemy else 1
	for slot in slots:
		var orig_pos: Vector2 = _original_slot_positions.get(slot, slot.position)
		slot.position.x = orig_pos.x * factor
	
	if team_label:
		team_label.text = "%s Team" % team_str
		team_label.position.x = abs(team_label.position.x) * factor


# Activates on turn start, collects actions sequentially, then executes them.
func _on_turn_started(team_playing: TeamManager) -> void:
	if team_playing != self:
		return
	assert(
		not tracked_characters.is_empty(),
		"Team '%s' has no characters." % name
	)
	
	# Capture the active turn ID as a cancellation token.
	var active_turn_id := turn_manager.current_turn
	var actions: Array[charAction] = []
	
	for character in tracked_characters:
		var action := await character.start_action()
		
		# Abort immediately if the turn was interrupted during the await.
		if turn_manager.current_turn != active_turn_id:
			return
		
		actions.append(action)
	
	for action in actions:
		action.execute()
	
	actions_finished.emit(actions)
	
	# Double check turn validity before concluding the turn.
	if turn_manager.current_turn == active_turn_id:
		turn_manager.end_turn()


# places the character into the first available slot
func _organize_character(character: testCharacter) -> void:
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
