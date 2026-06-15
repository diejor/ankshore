class_name DamageOverlay extends Node2D

## Spawns floating combat numbers from team resolution relays.

@export var teams: Array[TeamManager] = []
@export var damage_number_scene: PackedScene


func _ready() -> void:
	for team in teams:
		_connect_team(team)


## Replaces observed teams and connects their combat result relays.
func bind_teams(value: Array[TeamManager]) -> void:
	for team in teams:
		_disconnect_team(team)
	teams = value.duplicate()
	for team in teams:
		_connect_team(team)


# Wires one team into combat text spawning.
func _connect_team(team: TeamManager) -> void:
	if team == null:
		return
	if not team.character_beat_resolved.is_connected(_on_beat_resolved):
		team.character_beat_resolved.connect(_on_beat_resolved)
	if not team.character_move_resolved.is_connected(_on_move_resolved):
		team.character_move_resolved.connect(_on_move_resolved)


# Detaches one team from combat text spawning.
func _disconnect_team(team: TeamManager) -> void:
	if team == null:
		return
	if team.character_beat_resolved.is_connected(_on_beat_resolved):
		team.character_beat_resolved.disconnect(_on_beat_resolved)
	if team.character_move_resolved.is_connected(_on_move_resolved):
		team.character_move_resolved.disconnect(_on_move_resolved)


func _on_beat_resolved(
	character: Character,
	_beat: AttackBeat,
	blocked: bool,
	damage: int
) -> void:
	if damage <= 0:
		return
	var variant := DamageNumber.Variant.CHIP if blocked \
		else DamageNumber.Variant.HIT
	_spawn(character, damage, variant)


func _on_move_resolved(
	character: Character,
	move: CombatAction,
	hit: bool,
	damage: int
) -> void:
	if damage <= 0:
		return
	var variant := DamageNumber.Variant.HIT
	if move is Grab and not hit:
		variant = DamageNumber.Variant.COUNTER
	elif not hit:
		variant = DamageNumber.Variant.CHIP
	_spawn(character, damage, variant)


# Creates one floating number above the affected character.
func _spawn(
	character: Character,
	amount: int,
	variant: DamageNumber.Variant
) -> void:
	if character == null or damage_number_scene == null:
		return
	var number := damage_number_scene.instantiate() as DamageNumber
	if number == null:
		return
	add_child(number)
	number.global_position = character.global_position + Vector2(0.0, -120.0)
	number.start(amount, variant)
