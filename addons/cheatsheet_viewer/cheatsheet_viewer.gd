@tool
extends EditorPlugin

# Hi! I hope you are having a nice day!!
# This is the main script for the cheatsheet_viewer plugin!
#
# You can modify it if you want, but keep it mind the following things:
# - This is my first Godot Addon, I might do things the "wrong way"!
# - I wanted the plugin to work across projects, so lots of things are done "outside of the egine"
# - I wanted the plugin to be the least intruisive possible, so I did not use class_name, implicit script names, or autoloads
# - I wanted the plugin to be somewhat user friendly (this is why I made a ui for the settings)
#
# Because I like you, here is a little "how it works"
# 
# > Cheatsheets are just a directory with a png and a json
# > the plugin loads these images as TextRect
#
# Thats it! All the rest of the code is for Ui or settings or file management
# - Good luck!! - Christophe xoxoxox

## project settings > this key = dict[cheatsheet folder name: overriden settings]
const PROJECT_SETTINGS_CHEATSHEET_KEY = "plugin/cheatsheet_viewer/cheatsheets"
## Paths to .json
var detected_cheatsheet_json = []

## Data directory for cheatsheets
var persistent_plugin_path:String

## Hidden directory to store config that isnt pushed on git nor visible in project
var plugin_project_settings_dir:String

## Directory of the plugin, to set script of node relative to res://
var plugin_dir:String

# TEXTURES
## Path : TextureRect (with the floating_texture script)
var textures:Dictionary
var last_cheatsheet_pinned:TextureRect

# BOTTOM BUTTONS
var bottom_buttons := []
var sorted_bottom_buttons := [] ## buttons in order only
var buttons_container:Container ## contains all buttons + TextRect of cheatsheet
var settings_button:Button
var more_button:Button
var settings_popup:Window


# SHORTCUTS
## Shortcut : Index of the bottom_buttons to toggle
var shortcuts:Dictionary[Shortcut,int] = {}

## Shortcut to toggle to last pinned cheatsheet
var toggle_last_pinned_shortcut:Shortcut

func _enter_tree() -> void:
	
	var first_time_using_plugin := false
	
	# Handle paths
	_update_persistent_plugin_path()
	plugin_dir = self.get_script().resource_path.get_base_dir()
	plugin_project_settings_dir = ProjectSettings.globalize_path(plugin_dir.path_join("/.local_settings"))
	
	if not DirAccess.dir_exists_absolute(persistent_plugin_path):
		DirAccess.make_dir_recursive_absolute(persistent_plugin_path)
		first_time_using_plugin = true

	# Create directories / default settings
	create_local_project_settings()
	create_default_editor_settings()
	var editor_settings = EditorInterface.get_editor_settings()
	

	
	# Create button container (needed for next steps)
	buttons_container = HBoxContainer.new()
	buttons_container.z_index = 20
	
	# create the "see more" button
	if editor_settings.get_setting("plugin/cheatsheet_viewer/show_more_button"):
		more_button = Button.new()
		more_button.set_script(load(plugin_dir.path_join("/cheatsheet_viewer_category_button.gd")))
		more_button.button_script_path = plugin_dir.path_join("/cheatsheet_viewer_button.gd")
		more_button.setup()
	
	_add_control_in_bottom_panel_after_docks(buttons_container)
	
	var dir = DirAccess.open(persistent_plugin_path)
	if dir:
		for sub_dir_name in dir.get_directories():
			var sub_dir = DirAccess.open(persistent_plugin_path.path_join(sub_dir_name))
			if not sub_dir:continue
			for file in sub_dir.get_files():
			
				if file.ends_with(".json"):
					var json_path:=persistent_plugin_path.path_join("/"+sub_dir_name+"/"+file)
					
					detected_cheatsheet_json.append(json_path)
					create_from_json(json_path)
	if more_button:
		buttons_container.add_child(more_button)
		
	_add_settings_button()

	
	# Reorder button OR fill the editor setting with the current button order in the bottom panel
	var button_order = []
	if editor_settings.has_setting("plugin/cheatsheet_viewer/button_order"):
		button_order = editor_settings.get_setting("plugin/cheatsheet_viewer/button_order")
	button_order.erase("")
	if button_order == []:
		button_order = bottom_buttons.map(func(b):return b.folder_name)
	else:
		reorder_buttons(button_order)
	editor_settings.set_setting("plugin/cheatsheet_viewer/button_order",button_order)


	# Make the shortcuts
	EditorInterface.get_command_palette().add_command("Toggle Last Cheatsheet Pinned", "cheatsheet_viewer/toggle_last_pinned", func():last_cheatsheet_pinned.toggle())

	for i in range(1,10): #1 to 9
		var shortcut = editor_settings.get_shortcut("cheatsheet_viewer/Toggle Cheatsheet #%s"%i)
		if shortcut!=null:
			shortcuts[shortcut]=i
			editor_settings.add_shortcut("cheatsheet_viewer/Toggle Cheatsheet #%s"%i,shortcut)
			continue
		
		shortcut = Shortcut.new()
		var input_event = InputEventKey.new()
		
		# NOTE: Kinda works, classic "It works on my pc" issue
		# on mac it wasnt clear if it worked or not, but the setting displayed the correct shortcut
		#input_event.keycode = OS.find_keycode_from_string(str(i))
		input_event.physical_keycode = [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0][i-1]

		input_event.alt_pressed = true
		shortcut.events.append(input_event)
		editor_settings.add_shortcut("cheatsheet_viewer/Toggle Cheatsheet #%s"%i,shortcut)
		shortcuts[shortcut]=i
	
	toggle_last_pinned_shortcut = editor_settings.get_shortcut("cheatsheet_viewer/Toggle Last Cheatsheet Pinned")
	if toggle_last_pinned_shortcut==null:
		toggle_last_pinned_shortcut = Shortcut.new()
		var input_event = InputEventKey.new()
		input_event.keycode = KEY_C
		input_event.alt_pressed = true
		toggle_last_pinned_shortcut.events.append(input_event)
	editor_settings.add_shortcut("cheatsheet_viewer/Toggle Last Cheatsheet Pinned",toggle_last_pinned_shortcut)

	# Turn Off/On the shortcut process based on settings
	if editor_settings.has_setting("plugin/cheatsheet_viewer/enable_shortcuts"):
		set_process_shortcut_input(editor_settings.get_setting("plugin/cheatsheet_viewer/enable_shortcuts"))
	
	await get_tree().process_frame # just for fun
	
	# make it easier for first time users
	if first_time_using_plugin:
		_make_and_show_settings_popup()

func _disable_plugin() -> void:
	_exit_tree()

func _exit_tree() -> void:
	if is_instance_valid(buttons_container):
		buttons_container.queue_free()
		

	if is_instance_valid(settings_popup):
		settings_popup.queue_free()
		
	if is_instance_valid(settings_button):
		settings_button.queue_free()
		
	for text_rect in textures.values():
		if is_instance_valid(text_rect):
			text_rect.cleanup()
	
	bottom_buttons.clear()
	textures.clear()
	shortcuts.clear()
	detected_cheatsheet_json.clear()
	toggle_last_pinned_shortcut = null
	last_cheatsheet_pinned = null
	EditorInterface.get_command_palette().remove_command("cheatsheet_viewer/toggle_last_pinned")
	
# TODO: Texture rect are added as a child so it break the i index in shortcut
func _shortcut_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() : return
	
	if toggle_last_pinned_shortcut.matches_event(event):
		if last_cheatsheet_pinned:
			last_cheatsheet_pinned.toggle()
	
	for shortcut in shortcuts:
		if shortcut.matches_event(event):
			var i = shortcuts.get(shortcut)
			
			if i!=null and (sorted_bottom_buttons.size())>=i: 
				sorted_bottom_buttons[i-1].text_rect.toggle()
				print(i)
				#buttons_container.get_child(i-1).pressed.emit()# = !buttons_container.get_child(i-1).button_pressed
				#buttons_container.get_child(i-1).button_pressed = !buttons_container.get_child(i-1).button_pressed
				get_viewport().set_input_as_handled()
				break

#region Private Methods

## Updates the persistent_plugin_path var
func _update_persistent_plugin_path():
	var data_dir:= EditorInterface.get_editor_paths().get_data_dir()
	persistent_plugin_path = data_dir.path_join("plugin_cheatsheet_viewer")
	return persistent_plugin_path

func _add_control_in_bottom_panel_after_docks(control):
	var bottom_panel:Control = EditorInterface.get_base_control().find_children("*","EditorBottomPanel",true,false)[0]
	var hbox:HBoxContainer = bottom_panel.find_children("*","HBoxContainer",true,false)[0]
	hbox.add_child(control)
	
	# move after the vseparator, just before the bell icon
	hbox.move_child(control,2)
	
	# NOTE: this is a workaround that could fail i guess
	# it forces the editor to resize the bottom panel
	# otherwise buttons go out of the screen
	await get_tree().process_frame
	hbox.get_parent().current_tab = 1
	hide_bottom_panel()

func _make_and_show_settings_popup():
	if is_instance_valid(settings_popup):
		settings_popup.grab_focus()
		return
	settings_popup = Window.new()
	settings_popup.title = "Cheatsheet Viewer"
	var scene = load(plugin_dir.path_join("/cheatsheet_viewer_settings.tscn")).instantiate()
	scene.plugin_instance = self
	settings_popup.close_requested.connect(settings_popup.queue_free)
	settings_popup.add_child(scene)
	settings_popup.min_size = Vector2(610,650+12) *max(1.0,EditorInterface.get_editor_scale())
	scene.setup()
	EditorInterface.popup_dialog_centered(settings_popup,Vector2i(610,650+12)* max(1.0,EditorInterface.get_editor_scale()))

func _add_settings_button() -> void:
	if is_instance_valid(settings_button):
		settings_button.queue_free()
		#return
	
	settings_button = Button.new()
	settings_button.set_script(load(plugin_dir.path_join("/cheatsheet_viewer_button.gd")))
	settings_button.icon = EditorInterface.get_base_control().get_theme_icon("GDScript","EditorIcons")
	buttons_container.add_child(settings_button)
	bottom_buttons.append(settings_button)
	settings_button.tooltip_text = "[b]Cheatsheet Viewer Settings[/b][hr width=300][left]\n[b]Click[/b] to open settings and see all features[br][b]Ctrl+Click[/b] to get cool cheatsheets[br][b]Alt+Click[/b] to open cheatsheets directory"
	settings_button.pressed.connect(_on_settings_button_pressed)


func _on_settings_button_pressed():
	if Input.is_key_pressed(KEY_CTRL):
		OS.shell_open("https://qaqelol.itch.io/cheatsheet-viewer")
	elif Input.is_key_pressed(KEY_ALT):
		OS.shell_open(persistent_plugin_path)
	else:
		_make_and_show_settings_popup()

#endregion

#region Cool Methods

## Restarts the plugin
func restart():
	# this feels wrong but it works
	self._exit_tree()
	self._enter_tree()

## Reorder buttons if they are in the bottom panel, based on their directory name
func reorder_buttons(button_order:Array):
	sorted_bottom_buttons.clear()
	for folder_name in button_order:
		
		if folder_name=="":continue
		var idx = bottom_buttons.find_custom(func(b):return b.text_rect!=null and b.text_rect.folder_name==folder_name)
		if idx!=-1:
			# Move just before the settings button
			sorted_bottom_buttons.append(bottom_buttons[idx])
			buttons_container.move_child(bottom_buttons[idx],-3)

func get_and_validate_cheatsheet_image_path(json_path, image_path) -> String:
	if not image_path:
		push_warning("Cheatsheet Viewer: No valid image path for " + json_path)
	
	# Very basic support for different cheatsheets based on engine versions
	elif image_path is Dictionary:
		# if json contains different paths for different engine version, find the closest one
		var version:String = "{major}.{minor}".format(Engine.get_version_info()) # 4.6
		var index = image_path.keys().find(version)
		
		if index ==-1:
			# Version not found, so use the version before the current one
			index = image_path.keys().bsearch(version) - 1
			
			# If index wasnt a valid index, pick the one before
			if image_path.keys().get(index) == null:
				index-=1
			
			# Only newer versions are available 
			if index<0:
				push_warning("Cheatsheet Viewer: Cheatsheet made for newer engine versions (+%s) '%s')" % [image_path.keys()[0], json_path])
				return ""
		
		image_path = image_path[image_path.keys()[index]]
	
	image_path = json_path.rsplit("/",false,1)[0].path_join(image_path) #path relative to json location
	
	if not FileAccess.file_exists(image_path):
		push_error("Cheatsheet Viewer: Invalid image path '%s'" % image_path)
		return ""

	return image_path


## Creates a cheatsheet from a path pointing to a json file
func create_from_json(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cheatsheet Viewer: Cant read file " + path)
		return
	
	var data = JSON.parse_string(file.get_as_text())
	var image_path := get_and_validate_cheatsheet_image_path(path, data.get("image_path",""))
	
	if image_path=="":
		return # invalid image path
	
	var folder_name:String = path.rsplit("/")[-2]
	var data_in_settings = get_cheatsheet_in_project_settings(folder_name)
	
	# Project settings wins over global settings, if neither -> defaults to true
	var add_as_button:bool = data_in_settings.get("add_as_button",data.get("add_as_button", true))
	var add_as_command:bool = data_in_settings.get("add_as_command",data.get("add_as_command", true))
	
	# no reason to load this cheatsheet
	if not (add_as_button or add_as_command): return
	
	var text_rect = TextureRect.new()
	text_rect.set_script(load(plugin_dir.path_join("/cheatsheet_viewer_floating_texture.gd")))
	
	text_rect.nice_name = data.get("nice_name", "Cool cheatsheet without a name")
	text_rect.add_as_command = data.get("add_as_command", true)
	text_rect.quick_view_placement = data.get("quick_view_placement","center")
	text_rect.reference_url = data.get("reference_url","")
	text_rect.folder_name = folder_name
	text_rect.auto_scale = EditorInterface.get_editor_settings().get("plugin/cheatsheet_viewer/auto_scale")
	text_rect.quick_view_resets_position = EditorInterface.get_editor_settings().get("plugin/cheatsheet_viewer/quick_view_resets_position")
	text_rect.pinned.connect(func():last_cheatsheet_pinned=text_rect)
	text_rect.setup(image_path)
	

	if add_as_button:
		var button = Button.new()
		button.set_script(load(plugin_dir.path_join("/cheatsheet_viewer_button.gd")))
		button.text = data["button_label"]
		buttons_container.add_child(button)
		buttons_container.move_child(button,max(0,button.get_index()-1))
		button.setup(text_rect)
		button.quick_view_enabled = EditorInterface.get_editor_settings().get("plugin/cheatsheet_viewer/quick_view_enabled")
		button.flat = EditorInterface.get_editor_settings().get("plugin/cheatsheet_viewer/flat_buttons")
		button.folder_name = folder_name
		bottom_buttons.append(button)

	if more_button and add_as_command and not add_as_button:
		more_button.cheatsheets.append(text_rect)

	# NOTE: added here to allow clicking on the plugin button even if a cheatsheet is ontop (z-index is just visual)
	self.buttons_container.add_child(text_rect)
	#EditorInterface.get_base_control().add_child(text_rect) # cant use that one as explained in NOTE
	textures[path] = text_rect
	text_rect.hide()


	

func create_default_editor_settings():
	var settings = EditorInterface.get_editor_settings()

	if not settings.has_setting("plugin/cheatsheet_viewer/quick_view_enabled"):
		settings.set("plugin/cheatsheet_viewer/quick_view_enabled", true)

	if not settings.has_setting("plugin/cheatsheet_viewer/quick_view_hover_delay"):
		settings.set("plugin/cheatsheet_viewer/quick_view_hover_delay", 0.0)
		
	if not settings.has_setting("plugin/cheatsheet_viewer/auto_scale"):
		settings.set("plugin/cheatsheet_viewer/auto_scale", true)
		
	if not settings.has_setting("plugin/cheatsheet_viewer/flat_buttons"):
		settings.set("plugin/cheatsheet_viewer/flat_buttons", true)

	if not settings.has_setting("plugin/cheatsheet_viewer/quick_view_resets_position"):
		settings.set("plugin/cheatsheet_viewer/quick_view_resets_position", false)

	if not settings.has_setting("plugin/cheatsheet_viewer/show_more_button"):
		settings.set("plugin/cheatsheet_viewer/show_more_button", true)

## Creates a hidden directory within the addon, that isnt tracked with git, if it doesnt exists
## Used for user settings
func create_local_project_settings():
	# File already exists so assume the whole dir is already made
	if FileAccess.file_exists(plugin_project_settings_dir.path_join("/.gdignore")):
		return
	
	# Create a directory that will not be visible in godot, and not tracked with GIT
	# Because we want settings that are relative to local files (since cheatsheet are outside of the project)
	# If Person A disables all cheatsheets for this project, but person B wants them, they cant share one synched file
	
	DirAccess.make_dir_absolute(plugin_project_settings_dir)
	FileAccess.open(plugin_project_settings_dir.path_join("/.gdignore"), FileAccess.WRITE).close()
	var git_ignore_file = FileAccess.open(plugin_project_settings_dir.path_join("/.gitignore"), FileAccess.WRITE)
	git_ignore_file.store_string("*") # make git ignores the user settings directory for this addon
	git_ignore_file.close() 



func get_cheatsheet_in_project_settings(folder_name):
	var json_path = plugin_project_settings_dir.path_join("/override.json")
	var data = {}
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		data = JSON.parse_string(file.get_as_text())
		file.close()
	
	if folder_name in data:
		return data[folder_name]
	
	return {}
