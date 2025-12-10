@tool
extends VBoxContainer

var file_dialog: FileDialog
var output_folder_dialog: FileDialog
var result_text: TextEdit
var confirmation_dialog: ConfirmationDialog
var apply_to_all_checkbox: CheckBox
var output_location_option: OptionButton
var custom_output_button: Button
var generator = preload("res://addons/material_generator/material_generator.gd")

var pending_materials = []
var current_material_index = 0
var overwrite_all = false
var skip_all = false
var merge_all = false
var output_location_mode = 0  # 0=current, 1=parent, 2=custom
var custom_output_path = ""
var recursive_mode = true # Handle multiple material folders
var recursive_checkbox: CheckBox
var apply_texture_overrides = true
var texture_overrides_checkbox: CheckBox
var selected_folder_path = ""
var select_folder_button: Button
var generate_action_button: Button
var editor_plugin: EditorPlugin = null

func _ready():
	# var title = Label.new()
	# title.text = "Material Generator"
	# title.add_theme_font_size_override("font_size", 24)
	# add_child(title)
	# add_child(HSeparator.new())
	
	var main_container = HBoxContainer.new()
	
	var folder_selection_container = VBoxContainer.new()
	var generate_label = Label.new()
	generate_label.text = "Generate .tres Materials from Folder(s):"
	folder_selection_container.add_child(generate_label)
	
	select_folder_button = Button.new()
	select_folder_button.text = "Select Folder..."
	select_folder_button.pressed.connect(_on_select_folder_pressed)
	select_folder_button.add_theme_color_override("font_color", Color.YELLOW)
	folder_selection_container.add_child(select_folder_button)
	
	var checkbox_container = HBoxContainer.new()
	
	recursive_checkbox = CheckBox.new()
	recursive_checkbox.text = "Recursive"
	recursive_checkbox.button_pressed = true
	recursive_checkbox.tooltip_text = "When enabled, processes the selected folder and all subfolders.\nWhen disabled, only processes the selected folder itself."
	recursive_checkbox.toggled.connect(_on_recursive_toggled)
	checkbox_container.add_child(recursive_checkbox)
	
	texture_overrides_checkbox = CheckBox.new()
	texture_overrides_checkbox.text = "Override with AmbientCG compatible settings"
	texture_overrides_checkbox.text = "Gray Channel & Height Overrides"
	texture_overrides_checkbox.button_pressed = true
	texture_overrides_checkbox.tooltip_text = "Apply standard texture channel settings:\n• Roughness → Texture Channel: Gray\n• Ambient Occlusion → Texture Channel: Gray\n• Height → Scale: 1.0\n\nNote: Use these settings for materials with gray texture channels (similar to AmbientCG’s defaults)"
	texture_overrides_checkbox.toggled.connect(_on_texture_overrides_toggled)
	checkbox_container.add_child(texture_overrides_checkbox)
	
	folder_selection_container.add_child(checkbox_container)
	
	main_container.add_child(folder_selection_container)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	main_container.add_child(spacer)
	
	var output_location_container = VBoxContainer.new()
	var output_label = Label.new()
	output_label.text = "Output location(s):"
	output_location_container.add_child(output_label)
	
	var output_container = HBoxContainer.new()
	output_location_option = OptionButton.new()
	output_location_option.add_item("Same folder(s)", 0)
	output_location_option.add_item("Parent folder(s)", 1)
	output_location_option.add_item("Custom folder", 2)
	output_location_option.selected = 1
	output_location_mode = 1
	output_location_option.tooltip_text = "Same folder(s): Save .tres files inside each texture folder\nParent folder(s): Save .tres files in the parent directory of each texture folder\nCustom folder: Save all .tres files to a specific folder you choose"
	output_location_option.item_selected.connect(_on_output_location_changed)
	output_container.add_child(output_location_option)
	
	custom_output_button = Button.new()
	custom_output_button.text = "Select..."
	custom_output_button.visible = false
	custom_output_button.pressed.connect(_on_custom_output_pressed)
	output_container.add_child(custom_output_button)
	output_location_container.add_child(output_container)
	
	main_container.add_child(output_location_container)
	
	add_child(main_container)
	
	add_child(HSeparator.new())
	
	generate_action_button = Button.new()
	generate_action_button.text = "Generate Materials"
	generate_action_button.custom_minimum_size = Vector2(335, 80)
	generate_action_button.add_theme_font_size_override("font_size", 28)
	generate_action_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	generate_action_button.disabled = true
	generate_action_button.pressed.connect(_on_generate_materials_pressed)
	add_child(generate_action_button)
	
	add_child(HSeparator.new())
	
	result_text = TextEdit.new()
	result_text.text = ""
	result_text.editable = false
	result_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	result_text.custom_minimum_size = Vector2(0, 100)
	result_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(result_text)
	
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.dir_selected.connect(_on_folder_selected)
	add_child(file_dialog)
	
	output_folder_dialog = FileDialog.new()
	output_folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	output_folder_dialog.access = FileDialog.ACCESS_RESOURCES
	output_folder_dialog.dir_selected.connect(_on_custom_output_selected)
	add_child(output_folder_dialog)
	
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.min_size = Vector2i(600, 220)
	confirmation_dialog.exclusive = false
	confirmation_dialog.ok_button_text = "Overwrite"
	confirmation_dialog.cancel_button_text = "Skip"
	confirmation_dialog.confirmed.connect(_on_overwrite_confirmed)
	confirmation_dialog.canceled.connect(_on_skip_confirmed)
	confirmation_dialog.custom_action.connect(_on_custom_action)
	var merge_button = confirmation_dialog.add_button("Merge", false, "merge")
	
	var ok_button = confirmation_dialog.get_ok_button()
	var cancel_button = confirmation_dialog.get_cancel_button()
	var parent = ok_button.get_parent() if ok_button else null
	if parent:
		parent.move_child(cancel_button, 0)
		parent.move_child(ok_button, parent.get_child_count() - 1)
	
	if ok_button:
		ok_button.tooltip_text = "Replace the existing material file with a new one"
	if cancel_button:
		cancel_button.tooltip_text = "Keep the existing material file and skip generation"
	if merge_button:
		merge_button.tooltip_text = "Combine new textures with existing material properties"
	
	apply_to_all_checkbox = CheckBox.new()
	apply_to_all_checkbox.text = "Apply to all"
	apply_to_all_checkbox.button_pressed = false
	
	add_child(confirmation_dialog)

func _on_recursive_toggled(enabled: bool):
	recursive_mode = enabled

func _on_texture_overrides_toggled(enabled: bool):
	apply_texture_overrides = enabled

func _on_output_location_changed(index: int):
	output_location_mode = index
	custom_output_button.visible = (index == 2)
	if index != 2:
		custom_output_path = ""

func _on_custom_output_pressed():
	output_folder_dialog.popup_centered_ratio(0.5)

func _on_custom_output_selected(path: String):
	custom_output_path = path
	custom_output_button.text = "Selected: " + path.get_file()

func _refresh_inspector():
	# Simple filesystem scan - that's all we do
	if not editor_plugin:
		return
	
	var filesystem = EditorInterface.get_resource_filesystem()
	if filesystem:
		filesystem.scan()

func _set_result(text: String, is_error: bool = false, append: bool = false):
	if append and not result_text.text.is_empty():
		result_text.text += "\n" + text
	else:
		result_text.text = text
	if is_error:
		result_text.add_theme_color_override("font_color", Color.RED)
	else:
		result_text.remove_theme_color_override("font_color")

func _on_select_folder_pressed():
	if recursive_mode:
		file_dialog.title = "Select Parent Folder (will process all subfolders)"
	else:
		file_dialog.title = "Select Folder with Textures"
	file_dialog.popup_centered_ratio(0.5)

func _on_folder_selected(path: String):
	selected_folder_path = path
	var folder_name = path.get_file()
	if folder_name.is_empty():
		folder_name = path
	select_folder_button.text = "Selected: " + folder_name
	select_folder_button.remove_theme_color_override("font_color")
	generate_action_button.disabled = false

func _on_generate_materials_pressed():
	if selected_folder_path.is_empty():
		return
	
	overwrite_all = false
	skip_all = false
	merge_all = false
	pending_materials.clear()
	current_material_index = 0
	result_text.text = ""
	
	if recursive_mode:
		_process_batch(selected_folder_path)
	else:
		_process_single(selected_folder_path)

func _process_single(path: String):
	pending_materials = [path]
	current_material_index = 0
	var result = generator.generate_material(path, overwrite_all, _get_output_path(path), merge_all, apply_texture_overrides)
	_handle_result(result)

func _process_batch(parent_path: String):
	var dir = DirAccess.open(parent_path)
	if not dir:
		_set_result("Error: Could not open folder: " + parent_path, true)
		return
	
	var folders = [parent_path]
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			folders.append(parent_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	
	pending_materials = folders
	current_material_index = 0
	_process_next_material()

func _process_next_material():
	if current_material_index >= pending_materials.size():
		if recursive_mode:
			if result_text.text.is_empty():
				_set_result("Error: No texture files found in folder", true)
			else:
				result_text.text += "\n\nBatch processing complete!"
		_refresh_inspector()
		return
	
	var folder_path = pending_materials[current_material_index]
	var result = generator.generate_material(folder_path, overwrite_all, _get_output_path(folder_path), merge_all, apply_texture_overrides)
	_handle_result(result)

func _get_output_path(folder_path: String) -> String:
	match output_location_mode:
		0:  # Same folder
			return folder_path
		1:  # Parent folder
			return folder_path.get_base_dir()
		2:  # Custom folder
			if custom_output_path.is_empty():
				return folder_path.get_base_dir()
			return custom_output_path
		_:
			return folder_path.get_base_dir()

func _handle_result(result: Dictionary):
	var should_append = recursive_mode and current_material_index > 0
	
	# Handle multiple materials from a single folder
	if result.status == "multiple":
		for sub_result in result.results:
			_handle_single_result(sub_result, should_append, false)
			should_append = true
		current_material_index += 1
		if current_material_index < pending_materials.size():
			_schedule_next_material()
		else:
			if recursive_mode:
				result_text.text += "\n\nBatch processing complete!"
			_refresh_inspector()
		return
	
	_handle_single_result(result, should_append, true)

func _handle_single_result(result: Dictionary, should_append: bool, should_advance: bool):
	match result.status:
		"success":
			_set_result(result.message, false, should_append)
			if should_advance:
				current_material_index += 1
				if current_material_index < pending_materials.size():
					_schedule_next_material()
				else:
					if recursive_mode:
						result_text.text += "\n\nBatch processing complete!"
					_refresh_inspector()
		"error":
			if not (recursive_mode and result.message.contains("No texture files found")):
				_set_result(result.message, true, should_append)
			if should_advance:
				current_material_index += 1
				if current_material_index < pending_materials.size():
					_schedule_next_material()
				else:
					if recursive_mode and not result_text.text.is_empty():
						result_text.text += "\n\nBatch processing complete!"
					_refresh_inspector()
		"exists":
			if skip_all:
				_set_result("Skipped: " + result.path, false, should_append)
				if should_advance:
					current_material_index += 1
					if current_material_index < pending_materials.size():
						_schedule_next_material()
					else:
						if recursive_mode:
							result_text.text += "\n\nBatch processing complete!"
						_refresh_inspector()
			elif overwrite_all:
				var folder_path = pending_materials[current_material_index]
				var overwrite_result = generator.generate_material(folder_path, true, _get_output_path(folder_path), false, apply_texture_overrides)
				_handle_result(overwrite_result)  # Recursively handle in case of multiple materials
			elif merge_all:
				var folder_path = pending_materials[current_material_index]
				var merge_result = generator.generate_material(folder_path, false, _get_output_path(folder_path), true, apply_texture_overrides)
				_handle_result(merge_result)  # Recursively handle in case of multiple materials
			else:
				_show_overwrite_dialog(result.path)

func _show_overwrite_dialog(path: String):
	if file_dialog.visible:
		file_dialog.hide()
	
	apply_to_all_checkbox.button_pressed = false
	confirmation_dialog.dialog_text = "File already exists:\n" + path + "\n\n\n\n"
	
	if not apply_to_all_checkbox.get_parent():
		var vbox = confirmation_dialog.get_label().get_parent()
		if vbox:
			vbox.add_child(apply_to_all_checkbox)
	
	confirmation_dialog.title = "Confirm Overwrite"
	confirmation_dialog.popup_centered()

func _schedule_next_material():
	# Add a small delay to give filesystem time to update thumbnails
	await get_tree().create_timer(0.1).timeout
	_process_next_material()

func _on_overwrite_confirmed():
	var should_append = recursive_mode and current_material_index > 0
	if apply_to_all_checkbox.button_pressed:
		overwrite_all = true
	var folder_path = pending_materials[current_material_index]
	var result = generator.generate_material(folder_path, true, _get_output_path(folder_path), false, apply_texture_overrides)
	_set_result(result.message, result.status == "error", should_append)
	current_material_index += 1
	if current_material_index < pending_materials.size():
		_schedule_next_material()
	else:
		_refresh_inspector()

func _on_skip_confirmed():
	var should_append = recursive_mode and current_material_index > 0
	if apply_to_all_checkbox.button_pressed:
		skip_all = true
	var folder_path = pending_materials[current_material_index]
	var output_path = _get_output_path(folder_path).path_join(folder_path.get_file() + ".tres")
	_set_result("Skipped: " + output_path, false, should_append)
	current_material_index += 1
	if current_material_index < pending_materials.size():
		_schedule_next_material()
	else:
		_refresh_inspector()

func _on_custom_action(action: String):
	if not confirmation_dialog.visible:
		return
	
	confirmation_dialog.hide()
	var should_append = recursive_mode and current_material_index > 0
	
	match action:
		"merge":
			if apply_to_all_checkbox.button_pressed:
				merge_all = true
			var folder_path = pending_materials[current_material_index]
			var result = generator.generate_material(folder_path, false, _get_output_path(folder_path), true, apply_texture_overrides)
			_set_result(result.message, result.status == "error", should_append)
			current_material_index += 1
			if current_material_index < pending_materials.size():
				_schedule_next_material()
			else:
				_refresh_inspector()
