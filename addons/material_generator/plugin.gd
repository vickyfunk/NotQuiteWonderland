@tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/material_generator/material_generator_dock.tscn").instantiate()
	dock.editor_plugin = self
	add_control_to_bottom_panel(dock, "Material Generator")

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.free()
