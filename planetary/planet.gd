@tool
extends Node3D


@export var planet_data : PlanetData : 
	set(val):
		planet_data = val
		on_data_changed()
		if planet_data != null and not planet_data.is_connected("changed", on_data_changed):
			planet_data.connect("changed", on_data_changed)

	
# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		var face := child as PlanetMeshFace
		face.regenerate_mesh(planet_data)
		
		
func on_data_changed():
	#planet_data.min_height = 99999.0
	#planet_data.max_height = 0.0
	for child in get_children():
		var face := child as PlanetMeshFace
		face.regenerate_mesh(planet_data)
		
		
