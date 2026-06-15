class_name AttackStringView extends HBoxContainer

## Renders the beats of an [AttackString].
##
## Pure data view: assign [member attack_string] to render, pass
## [code]null[/code] to clear. Used as a preview during planning and
## string-building, and as the cue inside [DefensePromptUI] during
## resolution. Override [method _build_beat] in a subclass for richer
## visuals; the default is single-line labels.

@export var attack_string: AttackString:
	set(value):
		attack_string = value
		if is_node_ready():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	if attack_string == null:
		return
	for beat in attack_string.beats:
		add_child(_build_beat(beat))


# Builds the visual representation of one [AttackBeat].
func _build_beat(beat: AttackBeat) -> Control:
	var label := Label.new()
	label.text = beat.describe()
	return label
