@tool
extends PanelContainer

## Long code that mostly construct the UI for the settings
## Not very clean, but it works i think!

## The maing plugin instance, instead of using an autoload
var plugin_instance

## Labels that have metadata for the New Cheatsheet Helper Tab
var create_cheatsheet_labels = []

# Used to be @onready variables
var cheatsheet_creator_container: BoxContainer
var create_cheatsheet_rundown: RichTextLabel
var global_settings_container: BoxContainer
var manage_container: BoxContainer
var manage_global_container: BoxContainer

var create_cheatsheet_button: Button
var apply_global_settings_button: Button
var button_order_bar: TabBar

func setup() -> void:
	var editor_settings = EditorInterface.get_editor_settings()
	
	# these used to be @onready but this ensures it only gets setup when the popup is openned
	cheatsheet_creator_container = %CreateCheatsheetBoxContainer
	create_cheatsheet_rundown = %CreateCheatsheetRundown
	global_settings_container = %GlobalSettingsContainer
	manage_container = %ManageContainer
	manage_global_container = %ManageGlobalContainer

	create_cheatsheet_button = %CreateCheatsheetButton
	apply_global_settings_button = %ApplyGlobalSettingsButton
	button_order_bar = %ButtonOrderBar
	
	
	# Make UI
	make_ui_for_button_order()
	make_ui_for_cheatsheet_creation()
	make_ui_for_manage()
	make_ui_for_manage_global()
	
	# Set values based on current settings
	%QuickViewDelayBox.value = editor_settings.get_setting("plugin/cheatsheet_viewer/quick_view_hover_delay")
	%EnableQuickViewButton.button_pressed = editor_settings.get_setting("plugin/cheatsheet_viewer/quick_view_enabled")
	%QuickViewResetsPositions.button_pressed = editor_settings.get_setting("plugin/cheatsheet_viewer/quick_view_resets_position")
	%AutoScaleButton.button_pressed = editor_settings.get_setting("plugin/cheatsheet_viewer/auto_scale")
	%UseFlatButton.button_pressed = editor_settings.get_setting("plugin/cheatsheet_viewer/flat_buttons")
	%ShowMoreCheckBox.button_pressed = editor_settings.get_setting("plugin/cheatsheet_viewer/show_more_button")

	# Signals
	create_cheatsheet_button.pressed.connect(create_cheatsheet_from_fields)
	apply_global_settings_button.pressed.connect(apply_global_settings)
	%OverrideForProjectButton.pressed.connect(apply_global_settings.bind(true))
	%ManageTabContainer.tab_changed.connect(func(i):if i==0:make_ui_for_manage_global() else: make_ui_for_manage())
	%GlobalCheatsheetLabel.text = %GlobalCheatsheetLabel.text.replace("DATA_DIRECTORY", plugin_instance.persistent_plugin_path)
	%MadeByLabel.text = %MadeByLabel.text.replace("VERSION", plugin_instance.get_plugin_version())
	
	# User has no cheatsheet, so make the about tab pop first
	if plugin_instance.detected_cheatsheet_json.is_empty():
		$TabContainer.current_tab = 3
	else:
		$TabContainer.current_tab = 0

		
	# Show the project-wise managing cheatsheet tab if it's been used before
	if editor_settings.has_setting(plugin_instance.PROJECT_SETTINGS_CHEATSHEET_KEY):
		if FileAccess.file_exists(plugin_instance.plugin_project_settings_dir.path_join("/override.json")):
			%Project.show()
		
	
	# Ensures that the overriden font size matches the windows size
	# Its an ugly way to do it, but that way no theme variation are added to the engine
	var _editor_scale:float = max(1.0,EditorInterface.get_editor_scale())
	if _editor_scale!=1.0:
		for node:Label in $TabContainer/AboutContainer.find_children("*","Label",true):
			if node.has_theme_font_size_override("font_size"):
				node.add_theme_font_size_override("font_size",node.get_theme_font_size("font_size") * _editor_scale)
		
		for node:RichTextLabel in $TabContainer/AboutContainer.find_children("*","RichTextLabel",true):
			if node.has_theme_font_size_override("normal_font_size"):
				node.add_theme_font_size_override("normal_font_size",node.get_theme_font_size("normal_font_size") * _editor_scale)
			if node.has_theme_font_size_override("bold_font_size"):
				node.add_theme_font_size_override("bold_font_size",node.get_theme_font_size("bold_font_size") * _editor_scale)



#region Global Settings

func make_ui_for_button_order():
	button_order_bar.clear_tabs()
	var current_order = []
	if EditorInterface.get_editor_settings().has_setting("plugin/cheatsheet_viewer/button_order"):
		current_order = EditorInterface.get_editor_settings().get_setting("plugin/cheatsheet_viewer/button_order")

	var i := 0
	var folder_name_to_remove_from_order = []
	current_order.erase("")
	
	for folder_name in current_order:
		if not DirAccess.dir_exists_absolute(plugin_instance.persistent_plugin_path.path_join("/"+folder_name)):
			folder_name_to_remove_from_order.append(folder_name)
			print(folder_name," is missing")

			continue
		button_order_bar.add_tab(folder_name)
		button_order_bar.set_tab_tooltip(i,folder_name)
			
		i+=1

	for folder_name in folder_name_to_remove_from_order:
		current_order.erase(folder_name)
	
	i=0
	for json_path in plugin_instance.detected_cheatsheet_json:
		var file = FileAccess.open(json_path, FileAccess.READ)
		var valid = true
		if not file:
			push_error("Cheatsheet Viewer: Cant read file " + json_path)
			continue
	
		var folder_name = json_path.rsplit("/")[-2]
		if folder_name=="":
			file.close()
			continue
		var data = JSON.parse_string(file.get_as_text())
		
		if folder_name in current_order:
			var folder_exists = false
			for tab_i in button_order_bar.tab_count:
				if button_order_bar.get_tab_tooltip(tab_i) == folder_name:
					button_order_bar.set_tab_title(tab_i, data.get("button_label","(invalid)"+folder_name))
					if not plugin_instance.bottom_buttons.any(func(b):return b.folder_name==folder_name):
						button_order_bar.set_tab_disabled(tab_i,true)
					break
		else:
			print("no in current order ", folder_name)
			button_order_bar.add_tab(data.get("button_label","(invalid)"))
			button_order_bar.set_tab_tooltip(button_order_bar.tab_count-1,folder_name)
			
			if not plugin_instance.bottom_buttons.any(func(b):return b.folder_name==folder_name):
				button_order_bar.set_tab_disabled(i,true)
		#print(i, folder_name)
		i+=1
		file.close()

func apply_global_settings(restart:=false):
	#print("SETTING SAVED -----------------------")
	var editor_settings := EditorInterface.get_editor_settings()
	var needs_restart = false
	editor_settings.set_setting("plugin/cheatsheet_viewer/quick_view_hover_delay", %QuickViewDelayBox.value)
	editor_settings.set_setting("plugin/cheatsheet_viewer/quick_view_enabled", %EnableQuickViewButton.button_pressed)
	editor_settings.set_setting("plugin/cheatsheet_viewer/quick_view_resets_position", %QuickViewResetsPositions.button_pressed)
	editor_settings.set_setting("plugin/cheatsheet_viewer/auto_scale", %AutoScaleButton.button_pressed)
	editor_settings.set_setting("plugin/cheatsheet_viewer/flat_buttons",%UseFlatButton.button_pressed)
	
	if %ShowMoreCheckBox.button_pressed!=editor_settings.get_setting("plugin/cheatsheet_viewer/show_more_button"):
		needs_restart = true

	editor_settings.set_setting("plugin/cheatsheet_viewer/show_more_button",%ShowMoreCheckBox.button_pressed)
	

	for button in plugin_instance.bottom_buttons:
		if button == plugin_instance.settings_button:continue
		button.hover_delay = %QuickViewDelayBox.value
		button.quick_view_enabled = %EnableQuickViewButton.button_pressed
		button.flat = %UseFlatButton.button_pressed

	for text_rect in plugin_instance.textures.values():
		if is_instance_valid(text_rect):
			text_rect.auto_scale = %AutoScaleButton.button_pressed
			text_rect.quick_view_resets_position = %QuickViewResetsPositions.button_pressed
	 
	var button_order_as_folders = []
	for i in button_order_bar.tab_count:
		var folder_name = button_order_bar.get_tab_tooltip(i)
		if folder_name=="":continue

		button_order_as_folders.append(folder_name)

	editor_settings.set("plugin/cheatsheet_viewer/button_order",button_order_as_folders)
	plugin_instance.reorder_buttons(button_order_as_folders)
	
	editor_settings.set_setting("plugin/cheatsheet_viewer/enable_shortcuts", %EnableShortcutsCheckBox.button_pressed)
	plugin_instance.set_process_shortcut_input(%EnableShortcutsCheckBox.button_pressed)
	
	
	if restart or needs_restart:
		await get_tree().process_frame
		await get_tree().process_frame
		plugin_instance.restart()

#endregion

#region Manage Cheatsheets

func make_ui_for_manage():

	if plugin_instance.detected_cheatsheet_json.is_empty():
		return
	for child in manage_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	for json_path in plugin_instance.detected_cheatsheet_json:
		var file = FileAccess.open(json_path, FileAccess.READ)
		var valid = true
		if not file:
			push_error("Cheatsheet Viewer: Cant read file " + json_path)
			continue
	
		var data = JSON.parse_string(file.get_as_text())
		var image_path = plugin_instance.get_and_validate_cheatsheet_image_path(json_path, data.get("image_path",""))
		if image_path=="":
			valid=false
		manage_container.add_child(cheatsheet_manage_option(data, json_path.rsplit("/")[-2], valid, image_path))
		file.close()

func make_ui_for_manage_global():
	# no cheatsheet
	if plugin_instance.detected_cheatsheet_json.is_empty():
		return
		
	for child in manage_global_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	for json_path in plugin_instance.detected_cheatsheet_json:
		var file = FileAccess.open(json_path, FileAccess.READ)
		var valid = true
		if not file:
			push_error("Cheatsheet Viewer: Cant read file " + json_path)
			continue
	
		var data = JSON.parse_string(file.get_as_text())
		var image_path = plugin_instance.get_and_validate_cheatsheet_image_path(json_path, data.get("image_path",""))
		if image_path=="":
			valid=false
		manage_global_container.add_child(cheatsheet_manage_global_option(data, json_path.rsplit("/")[-2], valid, json_path))
		file.close()

func cheatsheet_manage_option(data:Dictionary, folder_name:String, valid:=true, image_path:=""):
	var layout = HBoxContainer.new()
	
	var label = Label.new()
	label.text = data.get("nice_name","Cheatsheet without a nice name")
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.custom_minimum_size.x = 220
	label.custom_minimum_size.y = 30
	label.tooltip_text = folder_name
	
	var button = CheckBox.new()
	button.text = "override"

	layout.add_child(button)
	layout.add_child(label)
	
	var data_in_settings = plugin_instance.get_cheatsheet_in_project_settings(folder_name)

	var check_controls = {}

	for k in ["add_as_button","add_as_command"]:
		var check = CheckBox.new()
		# set state based on project settings first, then globaly, or defaults to true
		check_controls[k] = check
		check.button_pressed = data_in_settings.get(k,data.get(k, true))

		check.custom_minimum_size.x = 100
		check.tooltip_text = "If enabled, this cheatsheet will always be added in the command palette (for this project)"
		if k == "add_as_button":
			check.tooltip_text = "If enabled, this cheatsheet will always appear as a button in the bottom bar (for this project)"
		check.toggled.connect(modify_project_settings.bind(folder_name,k))
		check.pressed.connect(make_ui_for_manage)
		layout.add_child(check)

	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if "add_as_button" in data_in_settings or "add_as_command" in data_in_settings:
		#modify_project_settings(check_controls["add_as_command"].button_pressed,folder_name,"add_as_command")
		#modify_project_settings(check_controls["add_as_button"].button_pressed,folder_name,"add_as_button")
		button.set_pressed_no_signal(true)
		layout.modulate.a = 1.0
	else:
		layout.mouse_filter = Control.MOUSE_FILTER_STOP
		layout.modulate.a = 0.5
		
	button.toggled.connect(func(pressed): if not pressed:remove_from_project_settings(folder_name))
	button.toggled.connect(func(pressed): if pressed:override_cheatsheet_for_project(check_controls["add_as_command"].button_pressed,check_controls["add_as_button"].button_pressed,folder_name))
	button.pressed.connect(make_ui_for_manage)

	return layout


func cheatsheet_manage_global_option(data:Dictionary,folder_name:String, valid:=true, json_path=""):
	var layout = HBoxContainer.new()
	
	var label = Label.new()
	label.text = data.get("nice_name","Cheatsheet without a nice name")
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.custom_minimum_size.x = 220
	label.custom_minimum_size.y = 20
	label.tooltip_text = folder_name
	if not valid:
		label.modulate = Color.TOMATO
		label.text+=" (invalid)"
	
	var button := Button.new()
	button.text = ""
	button.icon = EditorInterface.get_base_control().get_theme_icon("Folder","EditorIcons")
	button.flat = true
	button.modulate.a = 0.5
	#button.custom_minimum_size.x = 96/2
	button.tooltip_text = "Open the directory that contains this cheatsheet\nYou can delete the directory or edit the json manually for full control"
	button.pressed.connect(OS.shell_open.bind(json_path.rsplit("/",true,1)[-2]))
	

	var open_button:= Button.new()
	open_button.text = ""
	open_button.icon = EditorInterface.get_base_control().get_theme_icon("Image","EditorIcons")

	open_button.tooltip_text = "Open the cheatsheet image in the os image viewer"
	open_button.pressed.connect(OS.shell_open.bind(json_path.rsplit("/",true,1)[-2].path_join(data["image_path"])))
	
	layout.add_child(button)
	layout.add_child(open_button)
	layout.add_child(label)
	
	var check_controls = {}
	var cheatsheet_visible := false
	for k in ["add_as_button","add_as_command"]:
		var check = CheckBox.new()
		# set state based on project settings first, then globaly, or defaults to true
		check_controls[k] = check
		check.button_pressed = data.get(k, true)
		check.custom_minimum_size.x = 100
		if check.button_pressed:
			cheatsheet_visible = true
		check.tooltip_text = "If enabled, this cheatsheet will be added in the command palette by default"
		if k == "add_as_button":
			#check.text = data["button_label"]
			check.tooltip_text = "If enabled, this cheatsheet will appear as a button in the bottom bar by default"
		check.toggled.connect(func(pressed): data[k]=pressed; modify_cheatsheet_json(data,json_path))
		check.pressed.connect(make_ui_for_manage_global)
		layout.add_child(check)

	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	#button.pressed.connect(make_ui_for_manage_global)

	if not cheatsheet_visible:
		label.modulate.a = 0.5

	return layout



func override_cheatsheet_for_project(add_as_command, add_as_button, folder_name):
	modify_project_settings(add_as_command,folder_name,"add_as_command")
	modify_project_settings(add_as_button,folder_name,"add_as_button")


## Directly edits the global cheatsheet json
func modify_cheatsheet_json(data, json_path):
	
	var json = JSON.new()
	var save_file := FileAccess.open(json_path, FileAccess.WRITE)
	save_file.store_string(json.stringify(data))
	save_file.close()


func modify_project_settings(value, cheatsheet_folder, key):
	var json_path = plugin_instance.plugin_project_settings_dir.path_join("/override.json")
	var data = {}
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		data = JSON.parse_string(file.get_as_text())
		file.close()
	data.get_or_add(cheatsheet_folder,{})
	data[cheatsheet_folder][key] = value
	
	var json = JSON.new()
	var save_file := FileAccess.open(json_path, FileAccess.WRITE)
	save_file.store_string(json.stringify(data))
	save_file.close()

#func modify_project_settings(value, cheatsheet_folder, key):
	##var s := {}
	#var projects_dict:Dictionary = {}
	#var project_path = ProjectSettings.globalize_path("res://")
	#var settings:=EditorInterface.get_editor_settings()
	#if settings.has_setting(plugin_instance.PROJECT_SETTINGS_CHEATSHEET_KEY):
		#projects_dict = settings.get(plugin_instance.PROJECT_SETTINGS_CHEATSHEET_KEY)
	#
	#var s:Dictionary = projects_dict.get_or_add(project_path,{}) # path = {}
	#var current_data = s.get_or_add(cheatsheet_folder,{})
	#current_data[key] = value # add_as_button = true
	#s[cheatsheet_folder] = current_data # {folder_name = {add_as_button=true}}
	#projects_dict[project_path] = s
	#settings.set(plugin_instance.PROJECT_SETTINGS_CHEATSHEET_KEY,projects_dict)

func remove_from_project_settings(folder_name):
	var json_path = plugin_instance.plugin_project_settings_dir.path_join("/override.json")
	var data = {}
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		data = JSON.parse_string(file.get_as_text())
		file.close()
	
	if folder_name in data:
		data.erase(folder_name)
		if data.is_empty():
			DirAccess.remove_absolute(json_path)
		else:
			var json = JSON.new()
			var save_file := FileAccess.open(json_path, FileAccess.WRITE)
			save_file.store_string(json.stringify(data))
			save_file.close()

#endregion

#region New Cheatsheet Helper

func make_ui_for_cheatsheet_creation():
	for child in cheatsheet_creator_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	create_cheatsheet_labels.clear()
	
	cheatsheet_creator_container.add_child(create_string_option("Folder name","folder_name", "", "Name used for the folder (directory) that will be created in the plugin user_data (not in your project)\nThe name must be unique, with no special characters or spaces", "nice_example_uwu"))
	cheatsheet_creator_container.add_child(create_path_option("Image Path","image_path", "", "Cheatsheet image path. The image will be copied and pasted near godot editor's settings")) # TODO: more info on the path	
	cheatsheet_creator_container.add_child(create_string_option("User-friendly name","nice_name", "", "Name shown in command palette and user interface","Nice Example"))
	cheatsheet_creator_container.add_child(create_string_option("Button label","button_label", "", "Text/Emoji shown on bottom dock button. Shorter is better!", "🐸"))
	cheatsheet_creator_container.add_child(create_enum_option("Quick View placement", "quick_view_placement",["tooltip","center"], "Where the cheatsheet is shown when toggled.\ntooltip: Near the button that toggled it. Good for tall or small cheatsheets\ncenter: In the middle of the editor, good for large cheatsheets"))
	cheatsheet_creator_container.add_child(create_string_option("Reference URL","reference_url", "", "URL that opens on ctrl+click (like the docs)","https://docs.godotengine.org/en/latest/index.html"))
	cheatsheet_creator_container.add_child(create_bool_option("Add in command palette","add_as_command", true, "When checked, a 'toggle cheatsheet' command will be added to the command palette for this cheatsheet"))
	cheatsheet_creator_container.add_child(create_bool_option("Add button in bottom bar","add_as_button", true, "When checked, a button to toggle this cheatsheet will be added in the bottom bar\n(but user can modify this setting per project, per cheatsheet)"))

func create_string_option(field_name:String, field_var:String, default="", hint="", placeholder=""):
	var control = LineEdit.new()
	control.text = default
	control.placeholder_text = placeholder
	control.custom_minimum_size.x = 200
	control.text_changed.connect(update_cheatsheet_creation_rundown.unbind(1))
	return create_option(field_name, field_var, control, hint)
	
func create_enum_option(field_name:String, field_var:String, options:Array, hint=""):
	var control = OptionButton.new()
	for o in options:
		control.add_item(o)
	control.selected = 0
	control.custom_minimum_size.x = 200
	control.item_selected.connect(update_cheatsheet_creation_rundown.unbind(1))
	return create_option(field_name, field_var, control, hint)
	
func create_path_option(field_name:String, field_var:String, default="", hint=""):
	var control = LineEdit.new()
	control.custom_minimum_size.x = 150 -2
	control.text = default
	control.text_changed.connect(update_cheatsheet_creation_rundown.unbind(1))
	var layout = create_option(field_name, field_var, control, hint)
	var button = Button.new()
	button.text = "..."
	button.custom_minimum_size.x = 50
	layout.add_child(button)
	button.pressed.connect(ask_for_image_path.bind((func(value):if value!="":control.text=value),control))
	
	return layout
	
func create_bool_option(field_name:String, field_var:String, default=false, hint=""):
	var control = CheckBox.new()
	control.set_pressed_no_signal(default)
	control.pressed.connect(update_cheatsheet_creation_rundown)
	#control.custom_minimum_size.x = 200
	return create_option(field_name, field_var, control, hint)
	
func create_option(field_name:String, field_var:String, control:Control, hint=""):
	var layout = HBoxContainer.new()
	
	var label = Label.new()
	label.text = field_name
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.custom_minimum_size.x = 250
	label.set_meta("control", control)
	label.set_meta("field_var", field_var)
	label.tooltip_text = hint
	control.tooltip_text = hint
	create_cheatsheet_labels.append(label)
	layout.add_child(label)
	layout.add_child(control)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	return layout

func get_fields_values():
	var fields = {}

	for label in create_cheatsheet_labels:
		var control = label.get_meta("control")
		if control is LineEdit:
			fields[label.get_meta("field_var")] = control.text
		elif control is CheckBox:
			fields[label.get_meta("field_var")] = control.button_pressed
		elif control is OptionButton:
			fields[label.get_meta("field_var")] = control.get_item_text(control.selected)
		else:
			prints("field not supported", label.text)
	return fields

## Updates the text explaining how the new cheatsheet will happen
func update_cheatsheet_creation_rundown():
	var fields = get_fields_values()
	var can_be_used:= false
	var is_valid:=false
	var text = ""
	for key in fields.keys():
		if key == "reference_url":continue
		if fields[key] is String and fields[key]=="":
			create_cheatsheet_rundown.text = ""
			create_cheatsheet_button.disabled = true
			return false

	if fields["folder_name"].is_valid_filename() and not fields["folder_name"].contains(" "):
		text+="[color=YELLOW_GREEN]A new folder named '{folder_name}' will be created in [hint='%s']the editor data directory[/hint][/color]" % plugin_instance.persistent_plugin_path

		if FileAccess.file_exists(fields["image_path"]):
			text += "[ul]Image will be copied into '{folder_name}'[/ul]"
			is_valid = true
		else:
			text += "[color=TOMATO][ul]Invalid Image path[/ul][/color]"
			is_valid = false
		text += "[ul]Cheatsheet configuration json will be created in '{folder_name}'[/ul]"
	else:
		text += "[color=tomato]Folder Name is invalid or already exists[/color]"
		is_valid = false
		
	
	text+="[br]By default, this cheatsheet will :"
	if fields["reference_url"] != "":
		text+="[ul]"
		text+=("open [hint='{reference_url}']an url[/hint] when ctrl+clicked".format(fields))#.replace("[","[lb]"))
		text+="[/ul]"
	
	if fields["add_as_command"]:
		text+="[ul]"
		text+=("be shown in the command palette as 'cheatsheets/toggle {nice_name}'".format(fields).replace("[","[lb]"))
		text+="[/ul]"
		can_be_used = true
		
	if fields["add_as_button"]:
		text+= "[ul]"
		text+= "be linked to a button named '{button_label}' in the bottom bar".format(fields).replace("[","[lb]")
		text+= "[/ul]"
		can_be_used = true
		
	if not can_be_used:
		text+="[ul][color=ORANGE]be hidden unless user enables it as a command and or button in the settings[/color][/ul]"
	create_cheatsheet_rundown.text = text.format(fields)
	create_cheatsheet_button.disabled = !is_valid
	return is_valid

func create_cheatsheet_from_fields():
	if not update_cheatsheet_creation_rundown(): 
		return
	
	var fields:Dictionary = get_fields_values()
	var folder_name = fields["folder_name"]
	fields.erase("folder_name")
	
	
	var original_image_path = fields["image_path"]
	if not FileAccess.file_exists(original_image_path):
		push_error("Cheatsheet Viewer: Invalid image path")
		return
		
	var dir = plugin_instance.persistent_plugin_path.path_join("/"+folder_name)
	DirAccess.make_dir_absolute(dir)
	
	var image_name = "%s_cheatsheet.%s" % [folder_name,original_image_path.rsplit(".")[-1]]
	#print(image_name)
	var copy_to_path = dir.path_join("/"+image_name)
	DirAccess.copy_absolute(original_image_path, copy_to_path)
	fields["image_path"] = image_name # also relative path for cheatsheet in json
	
	var json = JSON.new()
	var save_file := FileAccess.open(dir.path_join("/"+folder_name+".json"), FileAccess.WRITE)
	save_file.store_string(json.stringify(fields))
	save_file.close()
	
	await get_tree().process_frame
	create_cheatsheet_rundown.text = "[color=YELLOW_GREEN]Cheatsheet created!! You did it!![/color]"
	plugin_instance.create_from_json(dir.path_join("/"+folder_name+".json"))
	plugin_instance.detected_cheatsheet_json.append(dir.path_join("/"+folder_name+".json"))
	make_ui_for_cheatsheet_creation()
	await get_tree().process_frame
	await get_tree().process_frame
	make_ui_for_manage()
	make_ui_for_manage_global()

## Spawns a file dialog and handles everything when its closed. Connect selected files to callable
func ask_for_image_path(callable:Callable, text_control=null):
	var dialog = FileDialog.new()
	dialog.filters = ["*.png,*.jpg,*.jpeg;Image Files;image/png,image/jpeg"]
	dialog.file_mode =FileDialog.FILE_MODE_OPEN_FILE
	add_child(dialog)
		#dialog.current_file = text_control.text
	#dialog.ok_button_text = "Select"
	dialog.recent_list_enabled = true
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.overwrite_warning_enabled = false
	dialog.popup_file_dialog()
	if text_control:
		if FileAccess.file_exists(text_control.text):
			dialog.current_path = text_control.text
			dialog.current_file = text_control.text
	
	# handle cases where user quits without selecting anything
	dialog.close_requested.connect(func(): dialog.file_selected.emit(""))
	# call given callable, passing a path and free dialog after
	dialog.file_selected.connect(func(x):callable.call(x);dialog.queue_free())

#endregion

## Quick About tab utility that opens the tabs/website on url click
func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	if meta:
		if str(meta).is_valid_int():
			$TabContainer.current_tab = str(meta).to_int()
		else:
			meta = meta.replace("SETTINGS_DIRECTORY", plugin_instance.plugin_project_settings_dir)
			OS.shell_open(meta.replace("DATA_DIRECTORY",plugin_instance.persistent_plugin_path))
