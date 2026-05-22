class_name TeamManager extends Node2D

## One side of a combat encounter.
##
## Owns the roster of [member tracked_characters] and their [member slots]
## layout. Turn flow lives on [TurnManager]; this class only exposes
## [member is_attacker] and [method pending_characters] for phases to
## consume.

enum Team {
	Ally,
	Enemy
}

@export var teamTitle: String = "test_teamTitle"

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

## True when this team currently holds the attacker role.
var is_attacker: bool:
	get:
		return turn_manager and turn_manager.attacker_team == self

## Characters registered to this team.
var tracked_characters: Array[Character] = []

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
		var orig_pos: Vector2 = _original_slot_positions.get(
			slot, slot.position
		)
		slot.position.x = orig_pos.x * factor
	
	if team_label:
		team_label.text = "%s Team" % team_str
		team_label.position.x = abs(team_label.position.x) * factor


## Returns the alive characters of this team that still need to plan
## an action this turn. Consumed by [PlanningPhase].
func pending_characters() -> Array[Character]:
	var result: Array[Character] = []
	for character in tracked_characters:
		if character and character.is_alive():
			result.append(character)
	return result


# Places the character into the first available slot.
func _organize_character(character: Character) -> void:
	for slot in slots:
		if not slot.selected:
			slot.selected = character
			return


# Registers any Character child and assigns it a slot.
func _on_child_entered(node: Node) -> void:
	if Engine.is_editor_hint():
		return
	if node is Character:
		tracked_characters.append(node)
		_organize_character(node as Character)
