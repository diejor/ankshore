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
@onready var _planning_preview: PanelContainer = $PlanningPreview
@onready var _move_label: Label = $PlanningPreview/VBox/MoveLabel
@onready var _string_view: AttackStringView = (
	$PlanningPreview/VBox/AttackStringView
)
@onready var _target_arrow: TargetArrowView = $TargetArrowView

@export var preview_move_name: String = ""


func _ready() -> void:
	if _character == null:
		push_warning("CharacterOverlay parent is not a Character.")
		_refresh_preview_data()
		return
	if _character.stats == null:
		_refresh_preview_data()
		return
	_character.pending_action_changed.connect(_on_pending_action_changed)
	_character.pending_target_changed.connect(_on_pending_target_changed)
	_target_arrow.character = _character
	_bind_stats(_character.stats)
	_render()
	_refresh_planning()


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


# Updates the committed action preview from character state.
func _refresh_planning() -> void:
	var action := _character.pending_action
	if action == null:
		_planning_preview.hide()
		_string_view.attack_string = null
		return
	_move_label.text = action.name
	var target := _first_pending_target()
	var attack := action as CombatAction
	if attack and attack.attack_string and target and target != _character:
		_string_view.attack_string = attack.attack_string
	else:
		_string_view.attack_string = null
	_planning_preview.show()


# Shows scene-authored mock data while editing the overlay in isolation.
func _refresh_preview_data() -> void:
	if preview_move_name.is_empty():
		return
	_move_label.text = preview_move_name
	_planning_preview.show()


func _on_pending_action_changed(_action: CharacterAction) -> void:
	_refresh_planning()


func _on_pending_target_changed(_target: Character) -> void:
	_refresh_planning()


# Returns the first committed target for single-target previews.
func _first_pending_target() -> Character:
	for target in _character.pending_targets:
		if target:
			return target
	return null


# Hook for a future Will bar.
func _on_will_changed(_current: int, _max_val: int) -> void:
	pass


# Hook for a future Courage indicator.
func _on_courage_changed(_current: int, _max_val: int) -> void:
	pass
