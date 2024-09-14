@tool
extends EditorPlugin

var panel
const TOOL_PANEL = preload("res://addons/terraingenerator/tool_panel.tscn")

func _enter_tree():
	panel = TOOL_PANEL.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, panel)
	

func _exit_tree():
	remove_control_from_docks(panel)
	panel.queue_free()
