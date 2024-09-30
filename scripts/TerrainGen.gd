@tool

extends MeshInstance3D

@export var xSize = 10
@export var zSize = 20
@export var max_height = 12
@export var min_height = 1
@export var frequency = 0.05
@export var octaves = 3
@export var update = false
@export var lacunarity = 2.0
@export var persistence = 0.5
@export var clear_vert_vis = false

var amplitude = max_height / 2

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_terrain()

func generate_terrain():
	var a_mesh:ArrayMesh
	var surftool = SurfaceTool.new()
	var n = FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = 0.1
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(zSize + 1):
		for x in range(xSize + 1):
			var t_frequency = frequency
			var t_amplitude = amplitude
			var y = amplitude

			for k in range(octaves):
				var sample_x = x * t_frequency
				var sample_z = z * t_frequency
				y += n.get_noise_2d(sample_x, sample_z) * t_amplitude
				t_frequency *= lacunarity
				t_amplitude *= persistence
				
			y = clamp(round(y), min_height, max_height)
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if update:
		generate_terrain()
	update = false
	
	if clear_vert_vis:
		for i in get_children():
			i.free()
