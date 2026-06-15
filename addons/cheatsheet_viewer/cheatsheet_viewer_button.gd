@tool
extends Button

signal hover_started
signal hover_finished

var hover_tween:Tween

var quick_view_enabled = true
var hover_delay:float = 0.00
var tooltip_node = self

var text_rect:TextureRect
var folder_name:String=""

func setup(bind_to:TextureRect):
	toggle_mode = true
	focus_mode = Control.FOCUS_CLICK

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	text_rect = bind_to
	pressed.connect(_on_pressed)
	
	hover_started.connect(text_rect.quick_view.bind(tooltip_node))
	hover_finished.connect(text_rect.hide)
	text_rect.visibility_changed.connect(_reflect_text_rect_state)
	
	if not text_rect.setup_finished.has_connections():
		text_rect.setup_finished.connect(text_rect.move_based_on_quick_view_placement.bind(tooltip_node),CONNECT_ONE_SHOT)
	



func _on_pressed():
	
	# Otherwise wont work on mac
	var ctrl_or_meta_key = KEY_META if OS.get_name() == "macOS" else KEY_CTRL
	if Input.is_physical_key_pressed(ctrl_or_meta_key):
		text_rect.open_reference_url()
		_reflect_text_rect_state()
		return
		
	if Input.is_key_pressed(KEY_ALT):
		text_rect.open_in_os()
		_reflect_text_rect_state()
		return
		
	if Input.is_key_pressed(KEY_SHIFT):
		text_rect.scale_based_on_window()
		text_rect.clamp_within_window()
		text_rect.move_based_on_quick_view_placement(tooltip_node)
		_reflect_text_rect_state()
		text_rect.pin()
		return

	
	if text_rect.is_pinned:
		text_rect.unpin()
	else:
		text_rect.pin()

func _on_mouse_entered():
	if not quick_view_enabled: return
	if text_rect and text_rect.is_pinned: return
	if hover_tween:hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_interval(hover_delay)
	hover_tween.tween_callback(hover_started.emit)
	

func _on_mouse_exited():
	if hover_tween and is_instance_valid(hover_tween):
		hover_tween.kill()
	if text_rect and text_rect.is_pinned: return
	hover_finished.emit()
	
func _make_custom_tooltip(for_text: String) -> Object:
	if for_text=="":return null
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.custom_minimum_size = Vector2(300,100)
	label.theme = EditorInterface.get_editor_theme()
	label.theme_type_variation = "EditorHelpBitTooltipContent"
	
	label.fit_content = true
	label.text = for_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode =TextServer.AUTOWRAP_OFF
	label.text = for_text
	return label
	
func _reflect_text_rect_state():
	if text_rect.visible and text_rect.is_pinned:
		self.set_pressed_no_signal(true)
	else:
		self.set_pressed_no_signal(false)
