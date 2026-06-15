@tool
extends Button

## Quickly added feature to list cheatsheets in a collabsible menu

var cheatsheets = []
var container:BoxContainer
var button_script_path

var hover_time_tween:Tween

func setup():
	toggle_mode = true
	focus_mode = Control.FOCUS_CLICK
	self.mouse_filter = Control.MOUSE_FILTER_PASS

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	container = VBoxContainer.new()
	self.icon = EditorInterface.get_base_control().get_theme_icon("GuiSpinboxUp","EditorIcons")
	container.mouse_exited.connect(_on_menu_exited)
	container.mouse_entered.connect(_on_menu_entered)
	self.add_child(container)
	container.hide()
	#self.top_level = true
	container.top_level = true
	container.z_index = 6
	
	if cheatsheets.is_empty():
		tooltip_text = "Cheatsheets that have no button but are enabled as a command will be added here"


func _on_pressed():
	if self.button_pressed:
		if not container.visible:
			show_menu()
	else:
		hide_menu()

func _on_mouse_entered():
	if hover_time_tween and hover_time_tween.is_running():
		hover_time_tween.kill()
	else:
		show_menu()
	
func _on_menu_entered():
	#print("menu in")
	if hover_time_tween: hover_time_tween.kill()

func _on_menu_exited():
	#print("menu out")
	if self.button_pressed:return
	if hover_time_tween: hover_time_tween.kill()
	hover_time_tween = create_tween()
	hover_time_tween.tween_interval(0.2)
	hover_time_tween.tween_callback(hide_menu)
	#hide_menu()

func _on_mouse_exited():

	if self.button_pressed:return
	if hover_time_tween: hover_time_tween.kill()
	hover_time_tween = create_tween()
	hover_time_tween.tween_interval(0.1)
	hover_time_tween.tween_callback(hide_menu)

func hide_menu():
	container.hide()

func show_menu():
	for c in container.get_children():
		if is_instance_valid(c):
			c.queue_free()

	await get_tree().process_frame
	
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var i = 0.0
	var last_suffix = ""
	
	for cheatsheet in cheatsheets:
		var button = Button.new()
		
		button.set_script(load(button_script_path))
		button.tooltip_node = button
		button.quick_view_enabled = true
		cheatsheet.quick_view_placement = "center"
		button.setup(cheatsheet)
		
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_entered.connect(_on_menu_entered)
		button.mouse_exited.connect(_on_menu_exited)
		
		button.z_index = 5
		button.z_as_relative = false
		
		button.text = cheatsheet.nice_name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if cheatsheet.is_pinned:
			button.set_pressed_no_signal(true)
		
		# add space between categories 
		if ": " in cheatsheet.nice_name:
			var suffix = cheatsheet.nice_name.split(":", true, 1)[0]
			if suffix!=last_suffix:
				i+=1.0
				var l = Label.new()
				l.text = suffix
				container.add_spacer(false)
				container.add_spacer(false)

			last_suffix = suffix
			button.text = cheatsheet.nice_name.replace(last_suffix+":","")

		container.add_child(button)
	
	await get_tree().process_frame
	container.reset_size()
	container.global_position = self.global_position
	container.global_position.y -= container.size.y + 2 
	container.global_position.x -= container.size.x/2.0
	container.show()
