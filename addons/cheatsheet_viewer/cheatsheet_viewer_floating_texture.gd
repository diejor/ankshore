@tool
extends TextureRect

signal pressed
signal closed
signal setup_finished
signal pinned


# Information
var image_path:String
var image_size:Vector2
var nice_name := ""
var folder_name := ""

## URL to a documentation page or file, opens when ctrl + click
var reference_url := ""

# Behavior settings
var add_as_command := true
var auto_scale := true
var quick_view_resets_position := false

## Either tooltip or center
var quick_view_placement = ""

# Manage/State
var tween:Tween
var is_pinned := false
var was_shown_before = false

## If the cheatsheet exists as a command in the command palette, right now
var added_as_a_command := false

## For dragging around
var mouse_offset:Vector2

var ctrl_or_meta_key:Key # for mac support

func setup(path):
	ctrl_or_meta_key = KEY_META if OS.get_name() == "macOS" else KEY_CTRL
	
	image_path = path
	var img:Image = Image.load_from_file(path)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	#texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	#img.generate_mipmaps(false)
	image_size = img.get_size()
	texture = ImageTexture.create_from_image(img)
	top_level = true
	z_index = 5
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset_ratio = Vector2(0.5,0.5)
	scale_based_on_window()
	move_to_window_center()
	EditorInterface.get_base_control().resized.connect(clamp_within_window.bind(100))
	
	if add_as_command:
		add_in_command_palette()
	if quick_view_placement == "tooltip":
		set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	elif quick_view_placement == "center":
		set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	else:
		set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	setup_finished.emit()


func _gui_input(event: InputEvent) -> void:
	if not visible:return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.is_physical_key_pressed(ctrl_or_meta_key):
			open_reference_url()
			
		if Input.is_key_pressed(KEY_SHIFT):
			scale_based_on_window()
			clamp_within_window()
			
		if Input.is_key_pressed(KEY_ALT):
			open_in_os()
		mouse_offset = self.global_position - get_global_mouse_position()
		pressed.emit()

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var zoom_scale:float = 0.05 #2.0 * (event.factor if event.factor else 1.0) *0.1
			if Input.is_key_pressed(KEY_SHIFT):
				zoom_scale = 0.02
			self.scale.x +=zoom_scale
			self.scale.y +=zoom_scale
			self.scale = clamp(scale, Vector2.ONE*0.1, Vector2.ONE*5.0)
			clamp_within_window()
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var zoom_pos:Vector2 = get_local_mouse_position()
			var zoom_scale:float = 0.05#4.0 ** (-event.factor if event.factor else -1.0)#* 0.1
			if Input.is_key_pressed(KEY_SHIFT):
				zoom_scale = 0.02
			#self.scale = scale*-0.5
			self.scale.x -=zoom_scale
			self.scale.y -=zoom_scale
			self.scale = clamp(scale, Vector2.ONE*0.1, Vector2.ONE*5.0)
			clamp_within_window()
			return

	if event is InputEventPanGesture:
			# For scale, take swipe direction and apply damping to control speed
			var zoom_scale:float = event.delta.y * 0.01
			if Input.is_key_pressed(KEY_SHIFT):
				zoom_scale = 0.02
			self.scale.x +=zoom_scale
			self.scale.y +=zoom_scale
			self.scale = clamp(scale, Vector2.ONE*0.1, Vector2.ONE*5.0)
			clamp_within_window()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		self.hide()
		is_pinned = false
		closed.emit()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		self.global_position = get_global_mouse_position() + mouse_offset
		# Clamp inside of screen, use global pos to take scale in account
		clamp_within_window()


func scale_based_on_window():
	if not auto_scale: 
		self.scale = Vector2.ONE
		return
	var windows_size:Vector2 = EditorInterface.get_base_control().size
	
	# Scale to fit in screen
	
	self.scale = Vector2.ONE
	if set_scale and (image_size.y > windows_size.y or image_size.x > windows_size.x):
		var factor_x = (windows_size.x*0.95) / image_size.x
		var factor_y = (windows_size.y*0.95) / image_size.y
		self.scale *= min(factor_x,factor_y)

func move_to_window_center():
	# Fit in center of screen
	var windows_size:Vector2 = EditorInterface.get_base_control().size
	if set_position:
		global_position = EditorInterface.get_base_control().get_global_rect().get_center()
		global_position.x-=(image_size.x*scale.x)/2.0
		global_position.y-=(image_size.y*scale.y)/2.0

func clamp_within_window(margin:=100.0):
	var w_rect = EditorInterface.get_base_control().get_global_rect()
	global_position.x = clamp(global_position.x, -(w_rect.position.x+max(margin,size.x*scale.x))+margin, w_rect.end.x-margin)
	global_position.y = clamp(global_position.y, -(w_rect.position.y+max(margin,size.y*scale.y))+margin, w_rect.end.y-margin)


func pin():
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	is_pinned = true
	modulate.v = 1.0
	pinned.emit()
	if tween:
		tween.custom_step(10000)
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self,"position:y",10.0,0.00).as_relative()
	tween.tween_property(self,"position:y",-10.0,0.2).as_relative()

	
func unpin():
	visible = false
	is_pinned = false
	if tween:
		tween.custom_step(10000)

func toggle():
	visible = !visible
	self.modulate.v = 1.0
	if visible: 
		#fit_in_screen()
		is_pinned = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		pinned.emit()
		if not was_shown_before:
			move_based_on_quick_view_placement()
			was_shown_before = true
	else:
		is_pinned = false
		
	# required for command palette use
	visibility_changed.emit()
	

func cleanup():
	if added_as_a_command:
		var command_palette = EditorInterface.get_command_palette()
		command_palette.remove_command("cheatsheet_viewer/toggle_%s" % nice_name)
		added_as_a_command = false

	self.queue_free()

func add_in_command_palette():
	if added_as_a_command:return # just in case
	var command_palette = EditorInterface.get_command_palette()
	# external_command is a function that will be called with the command is executed.
	var command_callable = Callable(self, "toggle")#.bind(arguments)
	command_palette.add_command("Toggle Cheatsheet " + nice_name, "cheatsheet_viewer/toggle_%s" % nice_name, command_callable)
	added_as_a_command = true
	
func open_reference_url():
	if not reference_url:return
	OS.shell_open(reference_url)

func open_in_os():
	if not image_path:return
	OS.shell_open(image_path)
	
func quick_view(tooltip_node=null):
	if self.visible or self.is_pinned: return
	modulate.v = 0.85 # darker to indicate quick view vs pinned
	modulate.a = 1.0
	if not quick_view_resets_position:
		# Ensure the default position is good
		if not was_shown_before:
			move_based_on_quick_view_placement(tooltip_node)
			was_shown_before = true
		else:
			self.show()
		return
	
	was_shown_before = true
	scale_based_on_window()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_based_on_quick_view_placement(tooltip_node)

## Moves and shows the cheatsheet based on its placement mode
func move_based_on_quick_view_placement(tooltip_node=null):
	match self.quick_view_placement:

		"tooltip":
			# Move to center of screen if invalid OR never shown and used from command palette
			if tooltip_node==null or not is_instance_valid(tooltip_node):
				scale_based_on_window()
				move_to_window_center()
				clamp_within_window()
				self.show()

				return
			self.scale_based_on_window()
			global_position = tooltip_node.global_position
			global_position.x -= (self.size.x * self.scale.x)/2.0
			global_position.x += (tooltip_node.size.x/2.0)
			if (global_position.x + (size.x*scale.x))>EditorInterface.get_base_control().size.x:
				global_position.x += (EditorInterface.get_base_control().size.x - (global_position.x + (size.x*scale.x)))
			global_position.y -= (self.size.y * self.scale.y)
			global_position.y -= 10
			#clamp_within_window(-100)
			show()

		#"list":
			#self.scale_based_on_window()
			#if is_instance_valid(tooltip_node):
				#self.global_position.x = tooltip_node.global_position.x 
				#self.global_position.x -= (self.size.x * self.scale.x)
				#self.global_position.y = tooltip_node.global_position.y
				#self.global_position.y -= (self.size.y * self.scale.y)
				#self.show()
				#return
				#
			#global_position = get_global_mouse_position()
			#global_position.x -= (self.size.x * self.scale.x)
			#if (global_position.x + (size.x*scale.x))>EditorInterface.get_base_control().size.x:
				#global_position.x += (EditorInterface.get_base_control().size.x - (global_position.x + (size.x*scale.x)))
			#global_position.y -= (self.size.y * self.scale.y)
			#global_position.y -= 10
			
		"center":
			move_to_window_center()
			show()

		"":
			move_to_window_center()
			show()

	
