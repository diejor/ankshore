@tool
class_name CombatHandle extends Marker2D

## Runtime travel handle for character attack movement.
##
## Other characters can target this marker. The owning
## [Character]'s [AnimationPlayer] animates [member travel_progress] to
## move the character root toward [member target].

## Distance to stop short of [member target].
@export var standoff_px: float = 72.0

## Runtime destination handle used by the owning character's travel.
var target: CombatHandle = null

## Normalized root travel authored by the attack animation.
var travel_progress: float = 0.0:
	set(value):
		travel_progress = value
		_apply_travel()

var _home_global_position: Vector2 = Vector2.ZERO


## Captures the current root position and starts traveling toward
## [param target_handle].
func begin_travel(target_handle: CombatHandle) -> void:
	target = target_handle
	var root_node := _root_node()
	if root_node:
		_home_global_position = root_node.global_position
	travel_progress = 0.0


## Returns the owner to its captured home position and clears the target.
func end_travel() -> void:
	travel_progress = 0.0
	target = null


# Applies the current progress to the owning character root.
func _apply_travel() -> void:
	if target == null:
		return
	var root_node := _root_node()
	if root_node == null:
		return
	var to_target := target.global_position - _home_global_position
	var destination := target.global_position
	if to_target.length() > standoff_px:
		destination -= to_target.normalized() * standoff_px
	root_node.global_position = _home_global_position.lerp(
		destination,
		travel_progress
	)


# Returns the character root this handle drives.
func _root_node() -> Node2D:
	return get_parent() as Node2D
