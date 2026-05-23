class_name CharacterPanel extends VBoxContainer

## Deep info view for the [Character] currently in [InspectionState].
##
## Subscribes to [signal InspectionState.inspection_changed] and rebinds
## to the new character's [CharacterStats] signals on each transition.

@export var inspection: InspectionState:
	set(value):
		if inspection:
			inspection.inspection_changed.disconnect(_on_inspection_changed)
		inspection = value
		if inspection:
			inspection.inspection_changed.connect(_on_inspection_changed)
			if is_node_ready():
				_bind(inspection.inspected_character)

@onready var _name_label: Label = $NameLabel
@onready var _hp_label: Label = $HpLabel
@onready var _will_label: Label = $WillLabel
@onready var _courage_label: Label = $CourageLabel

var _bound_stats: CharacterStats = null


func _ready() -> void:
	if inspection:
		_bind(inspection.inspected_character)
	else:
		_clear()


func _on_inspection_changed(character: Character) -> void:
	_bind(character)


func _bind(character: Character) -> void:
	_disconnect_stats()
	if character == null or character.stats == null:
		_clear()
		return
	_bound_stats = character.stats
	_bound_stats.health_changed.connect(_on_health_changed)
	_bound_stats.will_changed.connect(_on_will_changed)
	_bound_stats.courage_changed.connect(_on_courage_changed)
	_render(character)


func _disconnect_stats() -> void:
	if _bound_stats == null:
		return
	if _bound_stats.health_changed.is_connected(_on_health_changed):
		_bound_stats.health_changed.disconnect(_on_health_changed)
	if _bound_stats.will_changed.is_connected(_on_will_changed):
		_bound_stats.will_changed.disconnect(_on_will_changed)
	if _bound_stats.courage_changed.is_connected(_on_courage_changed):
		_bound_stats.courage_changed.disconnect(_on_courage_changed)
	_bound_stats = null


func _clear() -> void:
	_name_label.text = "(none)"
	_hp_label.text = ""
	_will_label.text = ""
	_courage_label.text = ""


func _render(character: Character) -> void:
	var s := character.stats
	_name_label.text = s.title
	_hp_label.text = "HP: %d / %d" % [s.health, s.max_health]
	_will_label.text = "Will: %d / %d" % [s.will, s.max_will]
	_courage_label.text = "Courage: %d" % s.courage


func _on_health_changed(current: int, max_val: int) -> void:
	_hp_label.text = "HP: %d / %d" % [current, max_val]


func _on_will_changed(current: int, max_val: int) -> void:
	_will_label.text = "Will: %d / %d" % [current, max_val]


func _on_courage_changed(current: int, _max_val: int) -> void:
	_courage_label.text = "Courage: %d" % current
