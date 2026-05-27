class_name TargetArrowView extends Line2D

## Draws a committed target arrow from one [Character] to another.

@export var character: Character:
	set(value):
		if character:
			_disconnect_character(character)
		character = value
		if character:
			_connect_character(character)
		if is_node_ready():
			_refresh(character.pending_targets[0] if (
				character and not character.pending_targets.is_empty()
			) else null)

var _target: Character = null
var _head_color: Color = Color(1.0, 0.18, 0.12, 0.95)


func _ready() -> void:
	top_level = true
	z_index = 50
	global_position = Vector2.ZERO
	width = 4.0
	default_color = _head_color
	_refresh(character.pending_targets[0] if (
		character and not character.pending_targets.is_empty()
	) else null)


func _process(_delta: float) -> void:
	if visible:
		_sync_points()


func _draw() -> void:
	if get_point_count() < 2:
		return
	var start := get_point_position(0)
	var tip := get_point_position(1)
	var direction := (tip - start).normalized()
	if direction.length() <= 0.0:
		return
	var side := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		tip,
		tip - direction * 14.0 + side * 6.0,
		tip - direction * 14.0 - side * 6.0,
	])
	draw_colored_polygon(points, _head_color)


# Wires pending target updates for the bound character.
func _connect_character(value: Character) -> void:
	if not value.pending_target_changed.is_connected(_refresh):
		value.pending_target_changed.connect(_refresh)


# Detaches from a previous character binding.
func _disconnect_character(value: Character) -> void:
	if value.pending_target_changed.is_connected(_refresh):
		value.pending_target_changed.disconnect(_refresh)


# Stores the current target and toggles the arrow.
func _refresh(target: Character) -> void:
	_target = target
	visible = _target != null and _target != character
	if not visible:
		clear_points()
		queue_redraw()
		return
	_sync_points()


# Reprojects the target so the arrow follows moving characters.
func _sync_points() -> void:
	if _target == null or character == null:
		_refresh(null)
		return
	global_position = Vector2.ZERO
	clear_points()
	add_point(character.global_position)
	add_point(_target.global_position)
	queue_redraw()
