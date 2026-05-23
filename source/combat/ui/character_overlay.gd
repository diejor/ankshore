class_name CharacterOverlay extends Node2D

## World-space HUD that follows its parent [Character].
##
## Renders the character's current HP directly above their sprite.
## Subscribes to [member Character.stats] signals so updates are
## reactive; will and courage hooks are wired but visually inert until
## bars are added.

@onready var _character: Character = get_parent() as Character
@onready var _hp_bar: ProgressBar = $HpBar
@onready var _name_label: Label = $NameLabel


func _ready() -> void:
	if _character == null:
		push_warning("CharacterOverlay parent is not a Character.")
		return
	if _character.stats == null:
		return
	_bind_stats(_character.stats)
	_render()


func _bind_stats(stats: CharacterStats) -> void:
	stats.health_changed.connect(_on_health_changed)
	stats.will_changed.connect(_on_will_changed)
	stats.courage_changed.connect(_on_courage_changed)


func _render() -> void:
	var s := _character.stats
	_name_label.text = s.title
	_hp_bar.max_value = s.max_health
	_hp_bar.value = s.health


func _on_health_changed(current: int, max_val: int) -> void:
	_hp_bar.max_value = max_val
	_hp_bar.value = current


# Hook for a future Will bar.
func _on_will_changed(_current: int, _max_val: int) -> void:
	pass


# Hook for a future Courage indicator.
func _on_courage_changed(_current: int, _max_val: int) -> void:
	pass
