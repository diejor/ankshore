class_name DamageNumber extends Label

## Floating combat text that rises, fades, and frees itself.

enum Variant {
	HIT,
	CHIP,
	COUNTER,
	HEAL,
}

const LIFETIME_SEC := 0.75


## Starts the floating label for [param amount] and [param variant].
func start(amount: int, variant: Variant) -> void:
	text = _format_text(amount, variant)
	modulate = _color_for(variant)
	scale = Vector2.ONE * _scale_for(variant)
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 44.0, LIFETIME_SEC)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME_SEC)
	tween.finished.connect(queue_free)


# Formats signed combat text.
func _format_text(amount: int, variant: Variant) -> String:
	if variant == Variant.HEAL:
		return "+%d" % amount
	return "-%d" % amount


# Chooses display color by result kind.
func _color_for(variant: Variant) -> Color:
	match variant:
		Variant.HIT:
			return Color(1.0, 0.18, 0.12)
		Variant.CHIP:
			return Color(0.72, 0.72, 0.72)
		Variant.COUNTER:
			return Color(0.35, 0.75, 1.0)
		Variant.HEAL:
			return Color(0.25, 0.9, 0.35)
	return Color.WHITE


# Chooses relative label size by result kind.
func _scale_for(variant: Variant) -> float:
	match variant:
		Variant.HIT:
			return 1.6
		Variant.CHIP:
			return 1.0
		Variant.COUNTER:
			return 1.35
		Variant.HEAL:
			return 1.25
	return 1.0
