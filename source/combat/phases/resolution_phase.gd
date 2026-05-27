class_name ResolutionPhase extends RefCounted

## Executes the characters collected by [PlanningPhase] in descending
## initiative order.
##
## Each character's pending move is awaited in turn. Dead actors and
## moves whose targets are all dead are skipped. The phase plays out to
## completion - once planning commits, nothing interrupts it.

var _characters: Array[Character]
var _speed_rolls: Dictionary = {}


func _init(p_characters: Array[Character]) -> void:
	_characters = p_characters


func run(ctx: PhaseContext, turn_manager: TurnManager) -> void:
	_roll_speeds()
	_characters.sort_custom(
		func(a: Character, b: Character) -> bool:
			return _speed_rolls.get(a, 0) > _speed_rolls.get(b, 0)
	)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"resolution_in")

	for character in _characters:
		if not character or not character.is_alive():
			continue
		if not _has_live_target(character):
			continue
		turn_manager.action_started.emit(character)
		await character.execute_turn(ctx)
		turn_manager.action_finished.emit(character)

	if ctx.ui_animator:
		await ctx.ui_animator.play_and_finish(&"resolution_out")


func _roll_speeds() -> void:
	for character in _characters:
		var base := (
			character.stats.speed if character and character.stats
			else 0
		)
		_speed_rolls[character] = base + randi_range(0, 9)


func _has_live_target(character: Character) -> bool:
	for target in character.pending_targets:
		if target and target.is_alive():
			return true
	return false
