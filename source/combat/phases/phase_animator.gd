class_name PhaseAnimator extends Node

## Uniform completion signal for any animation driver used by a phase.
##
## Wraps either an [AnimationPlayer] (see [SimpleAnimator]) or an
## [AnimationTree] (see [TreeAnimator]) behind a single contract:
## call [method play] with a key, then [code]await[/code] [signal finished].
##
## For tree-driven sequences with multiple chained clips, the terminal
## clip is expected to invoke [method finish] via a Call Method Track.

signal finished


## Begins playback identified by [param key]. Override in subclasses.
func play(_key: StringName) -> void:
	push_error("PhaseAnimator.play() not implemented.")


## Emits [signal finished]. Wired to Call Method Tracks on terminal clips.
func finish() -> void:
	finished.emit()


## Convenience that calls [method play] then awaits [signal finished].
func play_and_finish(key: StringName) -> void:
	play(key)
	await finished
