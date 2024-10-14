@tool
extends MeshInstance3D

@export var xSize = 20
@export var zSize = 20
@export var max_height = 30
@export var min_height = 1
@export var update = false
@export var clear_vert_vis = false

var moisture : float
var y : float
var tree_min_distance = 5
@export var tree_scene : PackedScene



func _ready():
	generate_terrain()


func generate_terrain():
	var a_mesh:ArrayMesh
	var surftool = SurfaceTool.new()
	var n = FastNoiseLite.new()
	var m = FastNoiseLite.new()
	n.noise_type = FastNoiseLite.FRACTAL_FBM
	m.noise_type = FastNoiseLite.TYPE_SIMPLEX
	m.seed = 87654321
	n.seed = 12345678
	n.fractal_octaves = 3
	n.frequency = 0.02
	m.frequency = 0.1
	n.fractal_lacunarity = 2
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(zSize + 1):
		for x in range(xSize + 1):

			y = n.get_noise_2d(x, z) * (max_height - min_height)
			moisture = m.get_noise_2d(x, z)
			#print(biome(y, moisture))
			
			var color = biome(y, moisture)
			surftool.set_color(color)
			var uv = Vector2()
			uv.x = inverse_lerp(0, xSize, x)
			uv.y = inverse_lerp(0, zSize, z)
			surftool.set_uv(uv)
			surftool.add_vertex(Vector3(x,y,z))
	
	var vert = 0
	for z in zSize:
		for x in xSize:
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + xSize + 1)
				
			surftool.add_index(vert + xSize + 1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + xSize + 2)
			vert += 1
		vert += 1
	surftool.generate_normals()
	a_mesh = surftool.commit()
	
	mesh = a_mesh

func _process(delta):
	if update:
		generate_terrain()
	update = false
	
	if clear_vert_vis:
		for i in get_children():
			i.free()


# Function to get the terrain height at a given (x, z) position
func get_height_at_position(x, z):
	var n = FastNoiseLite.new()
	n.noise_type = FastNoiseLite.FRACTAL_FBM
	n.seed = 12345678
	n.fractal_octaves = 3
	n.frequency = 0.05
	return n.get_noise_2d(x, z) * 3


func biome(height, moisture):
	#place_trees()
	if (height < 0.1):
		#"OCEAN"
		return Color(0.0, 0.0, 0.8)  # Blue for ocean

	if (height < 0.12):
		#"BEACH"
		return Color(1.0, 0.9, 0.5)  # Sand color for beaches
	
	return Color(0.05, 0.7, 0.0)  # Default color (grassland)


#region
	if (height > 0.8):
		if (moisture < 0.1):
			# "SCORCHED"
			return Color(1.0, 1.0, 1.0)  # White for snow
		if (moisture < 0.2):
			#return "BARE"
			return Color(1.0, 1.0, 1.0)  # White for snow

		if (moisture < 0.5):
			#return "TUNDRA"
			return Color(1.0, 1.0, 1.0)  # White for snow

		else:
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "SNOW"
	  
	if (height > 0.6):
		if (moisture < 0.33):
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "TEMPERATE_DESERT"
		if (moisture < 0.66):
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "SHRUBLAND"
		else:
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "TAIGA"
	
	if (height > 0.3):
		if (moisture < 0.16):
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "TEMPERATE_DESERT"
		if (moisture < 0.50):
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "GRASSLAND"
		if (moisture < 0.83):
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "TEMPERATE_DECIDUOUS_FOREST"
		else:
			return Color(1.0, 1.0, 1.0)  # White for snow
			#return "TEMPERATE_RAIN_FOREST"
	
	if (moisture < 0.16):
		return Color(1.0, 1.0, 1.0)  # White for snow
		#return "SUBTROPICAL_DESERT"
	if (moisture < 0.33):
		return Color(1.0, 1.0, 1.0)  # White for snow
		#return "GRASSLAND";
	if (moisture < 0.66):
		return Color(1.0, 1.0, 1.0)  # White for snow
		#return "TROPICAL_SEASONAL_FOREST"
	else:
		return Color(1.0, 1.0, 1.0)  # White for snow
		#return "TROPICAL_RAIN_FOREST"
#endregion
