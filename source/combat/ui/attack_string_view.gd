class_name AttackStringView extends HBoxContainer

## Renders the beats and non-default ender of an [AttackString].
##
## Pure data view: assign [member attack_string] to render, pass
## [code]null[/code] to clear. Used as a preview during planning and as
## the cue inside [DefensePromptUI] during resolution. Override
## [method _build_beat] or [method _build_ender] in a subclass for
## richer visuals; the default is single-line labels.

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
	if attack_string.ender != AttackString.Ender.STRIKE:
		add_child(_build_ender(attack_string.ender))


# Builds the visual representation of one [AttackBeat].
func _build_beat(beat: AttackBeat) -> Control:
	var label := Label.new()
	label.text = beat.describe()
	return label


# Builds the ender chip.
func _build_ender(ender: int) -> Control:
	var label := Label.new()
	label.text = "[%s]" % AttackString.Ender.find_key(ender)
	return label
