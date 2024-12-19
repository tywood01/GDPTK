@tool
extends Resource

class_name PlanetData

@export var radius : int  = 5 : 
	set(val):
		radius = val
		set_radius()
		
@export var resolution : int  = 5 : 
	set(val):
		resolution = val
		set_resolution()
		
@export var noise_map : FastNoiseLite : 
	set(val):
		noise_map = val
		set_resolution()
		
@export var planet_color : GradientTexture1D : 
	set(value):
		planet_color = value
		if planet_color != null and not planet_color.is_connected("changed", on_data_changed):
			planet_color.connect("changed", on_data_changed)

var min_height := 99999.0
var max_height := 0.0
		
func set_radius():
	emit_signal("changed")
	
func set_resolution():
	emit_signal("changed")

func set_noise_map():
	emit_signal("changed")
	if noise_map != null and not noise_map.is_connected("changed", on_data_changed):
		noise_map.connect("changed", on_data_changed)
		
func on_data_changed():
	emit_signal("changed")
	
func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	var elevation = noise_map.get_noise_3dv(point_on_sphere)
	return point_on_sphere * radius * (elevation + 1.0)
	
	
