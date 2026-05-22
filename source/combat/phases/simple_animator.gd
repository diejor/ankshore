class_name SimpleAnimator extends PhaseAnimator

## [PhaseAnimator] backed by a single [AnimationPlayer].
##
## Use for one-shot UI animations (move list slide, target reticle pulse)
## where the playback is a single clip. For multi-clip sequences, prefer
## [TreeAnimator].

@export var player: AnimationPlayer


func _ready() -> void:
	if player and not player.animation_finished.is_connected(
		_on_animation_finished
	):
		player.animation_finished.connect(_on_animation_finished)


func play(key: StringName) -> void:
	if not player:
		push_error("SimpleAnimator has no player assigned.")
		finish()
		return
	player.play(key)


func _on_animation_finished(_anim: StringName) -> void:
	finish()
