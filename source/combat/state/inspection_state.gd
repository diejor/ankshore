class_name InspectionState extends Resource

## Shared "who is the player currently looking at?" state.
##
## One instance per encounter, written by view sources ([SlotSelectionView]
## on slot focus, [TeamState] on active-character changes) and read by
## panels that render details about one [Character] at a time
## ([CharacterPanel], [MoveListPanel], [AttackStringView]).
##
## [br][br]
## Decoupled from [TeamState] on purpose: inspection can drift to enemy
## characters during [constant TeamState.Phase.PICKING_TARGETS] and
## should survive phase changes without each panel having to track its
## own "last interesting character" heuristic.

## Emitted when [member inspected_character] changes, including
## transitions to and from [code]null[/code].
signal inspection_changed(character: Character)

## The character every bound panel should currently render. May be
## [code]null[/code] when nothing is being inspected.
var inspected_character: Character = null:
	set(value):
		if value == inspected_character:
			return
		inspected_character = value
		inspection_changed.emit(value)
