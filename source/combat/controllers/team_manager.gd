class_name TeamManager extends Node2D

## One side of a combat encounter.
##
## Owns the roster of [member tracked_characters], the slot layout, and
## the per-encounter [TeamState] resource that planning UI observes.
## Turn flow lives on [TurnManager], this class drives
## [method run_planning] when asked.

enum Team {
	## The ally team.
	Ally,
	## The enemy team.
	Enemy
}

signal character_added(character: Character)
signal character_defense_window_opened(
	character: Character,
	kind: Character.DefenseKind,
	beat: AttackBeat,
	window_sec: float
)
signal character_defense_window_closed(
	character: Character,
	result: DefenseInput
)
signal character_beat_resolved(
	character: Character,
	beat: AttackBeat,
	blocked: bool,
	damage: int
)
signal character_move_resolved(
	character: Character,
	move: CombatAction,
	hit: bool,
	damage: int
)

## Name of the team.
@export var teamTitle: String = "test_teamTitle"

## Which side this team belongs to.
@export var team: Team:
	set(value):
		team = value
		_apply_team_layout.call_deferred()

## Slots used to position characters on the field.
@export var slots: Array[SelectionSlot]

## Per-encounter planning state shared with controllers and views.
## Constructed in [method _init] - never authored as a [code].tres[/code]
## so the [Character] refs it holds remain scene-scoped.
var state: TeamState

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
	state = TeamState.new()
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
## an action this turn. Consumed by [method run_planning].
func pending_characters() -> Array[Character]:
	var result: Array[Character] = []
	for character in tracked_characters:
		if character and character.is_alive():
			result.append(character)
	return result


## Begins planning on [member state] and awaits
## [signal TeamState.planning_finished]. Returns the characters whose
## pending moves were committed by the bound controller.
##
## [br][br]
## Whoever is bound to [member state] (a [PlayerController] reading input,
## an [AIController] running policy, ...) drives the state machine to
## completion. This method just kicks it off and waits.
func run_planning() -> Array[Character]:
	var result: Array[Character] = []
	var on_action_committed := func(character: Character) -> void:
		result.append(character)

	for character in tracked_characters:
		if character:
			character.clear_pending_move()
	state.action_committed.connect(on_action_committed)
	state.begin_planning(pending_characters())
	if state.phase != TeamState.Phase.DONE:
		await state.planning_finished
	state.action_committed.disconnect(on_action_committed)
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
		var character := node as Character
		tracked_characters.append(character)
		_organize_character(character)
		character.defense_window_opened.connect(
			_relay_defense_window_opened.bind(character)
		)
		character.defense_window_closed.connect(
			_relay_defense_window_closed.bind(character)
		)
		character.beat_resolved.connect(
			_relay_beat_resolved.bind(character)
		)
		character.move_resolved.connect(
			_relay_move_resolved.bind(character)
		)
		character.tree_exiting.connect(
			_on_character_tree_exiting.bind(character)
		)
		character_added.emit(character)


# Disconnects relays when a character leaves the scene tree.
func _on_character_tree_exiting(character: Character) -> void:
	_disconnect_if_removed.call_deferred(character)


# Ignores slot reparenting and disconnects only true removals.
func _disconnect_if_removed(character: Character) -> void:
	if not is_instance_valid(character):
		tracked_characters.erase(character)
		return
	if is_ancestor_of(character):
		return
	tracked_characters.erase(character)
	var opened := _relay_defense_window_opened.bind(character)
	var closed := _relay_defense_window_closed.bind(character)
	var beat := _relay_beat_resolved.bind(character)
	var move := _relay_move_resolved.bind(character)
	if character.defense_window_opened.is_connected(opened):
		character.defense_window_opened.disconnect(opened)
	if character.defense_window_closed.is_connected(closed):
		character.defense_window_closed.disconnect(closed)
	if character.beat_resolved.is_connected(beat):
		character.beat_resolved.disconnect(beat)
	if character.move_resolved.is_connected(move):
		character.move_resolved.disconnect(move)


# Re-emits defense windows for subscribers interested in any teammate.
func _relay_defense_window_opened(
	kind: Character.DefenseKind,
	beat: AttackBeat,
	window_sec: float,
	character: Character
) -> void:
	character_defense_window_opened.emit(
		character, kind, beat, window_sec
	)


# Re-emits defense completion for subscribers interested in any teammate.
func _relay_defense_window_closed(
	result: DefenseInput,
	character: Character
) -> void:
	character_defense_window_closed.emit(character, result)


# Re-emits beat resolution for subscribers interested in any teammate.
func _relay_beat_resolved(
	beat: AttackBeat,
	blocked: bool,
	damage: int,
	character: Character
) -> void:
	character_beat_resolved.emit(character, beat, blocked, damage)


# Re-emits move resolution for subscribers interested in any teammate.
func _relay_move_resolved(
	move: CombatAction,
	hit: bool,
	damage: int,
	character: Character
) -> void:
	character_move_resolved.emit(character, move, hit, damage)
