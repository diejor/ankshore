class_name CombatSet extends Node2D
#the brain lol

@onready var ally_team: allyTeam = $AllyTeam
@onready var test_character: testCharacter = $AllyTeam/testCharacter


@onready var enemy_team: enemyTeam = $EnemyTeam
@onready var test_character_2: testCharacter = $EnemyTeam/testCharacter2



func _on_turn_manager_turn_ended() -> void:
	pass # Replace with function body.
