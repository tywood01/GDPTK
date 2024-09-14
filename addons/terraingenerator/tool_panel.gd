@tool
extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_regen_button_pressed():
	var selection = EditorInterface.get_selection()
	var xSize = %xSize
	var zSize = %zSize
	print("hello")


func _on_x_size_value_changed(value):
	print(%xSize)
	pass # Replace with function body.
