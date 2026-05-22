class_name TreeAnimator extends PhaseAnimator

## [PhaseAnimator] backed by an [AnimationTree] state machine.
##
## [method play] travels to the requested state. The terminal clip of
## that branch must invoke [method PhaseAnimator.finish] via a Call
## Method Track so the awaiter is released exactly once per sequence.
##
## [codeblock]
##     await tree_animator.play_and_finish(&"attack_combo")
## [/codeblock]

@export var tree: AnimationTree

var _state_machine: AnimationNodeStateMachinePlayback


func _ready() -> void:
	if tree:
		_state_machine = tree.get(&"parameters/playback")


func play(key: StringName) -> void:
	if not _state_machine:
		push_error("TreeAnimator has no state machine playback.")
		finish()
		return
	_state_machine.travel(key)
