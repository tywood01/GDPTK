@tool
extends StaticBody3D

@export var xSize = 25  # Match CHUNK_SIZE
@export var zSize = 25 # Match CHUNK_SIZE
@export var max_height = 16
@export var min_height = 1
@export var frequency = 0.05
@export var octaves = 3
@export var lacunarity = 2.0
@export var persistence = 0.5
@export var chunk_size = 25 # Ensure this matches CHUNK_SIZE from the chunk script

var amplitude = max_height / 2

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_terrain(Vector2(0, 0))  # Start with the initial chunk

# Generate terrain based on chunk coordinates
func generate_terrain(chunk_coords: Vector2):
	# Clear existing children for fresh terrain generation
	for child in get_children():
		child.queue_free()

	# Create the mesh with SurfaceTool
	var a_mesh: ArrayMesh
	var surftool = SurfaceTool.new()
	var n = FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = frequency
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Offset for chunk generation based on chunk position in the world
	var chunk_offset = Vector3(chunk_coords.x * chunk_size, 0, chunk_coords.y * chunk_size)

	# Create the vertices, ensuring that the noise generation is consistent across chunks
	for z in range(zSize + 1):
		for x in range(xSize + 1):
			var t_frequency = frequency
			var t_amplitude = amplitude
			var y = 0.0

			# Generate noise-based terrain height using octave noise
			for k in range(octaves):
				# Adjust coordinates for noise to ensure seamless chunk transitions
				var sample_x = (chunk_offset.x + x) * t_frequency
				var sample_z = (chunk_offset.z + z) * t_frequency
				y += n.get_noise_2d(sample_x, sample_z) * t_amplitude
				t_frequency *= lacunarity
				t_amplitude *= persistence
				
			y = clamp(y, min_height, max_height)  # Clamp the height between min and max values
			var uv = Vector2(inverse_lerp(0, xSize, x), inverse_lerp(0, zSize, z))
			surftool.set_uv(uv)
			surftool.add_vertex(Vector3(chunk_offset.x + x, y, chunk_offset.z + z))
	
	# Create the triangle indices
	var vert = 0
	for z in range(zSize):
		for x in range(xSize):
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + xSize + 1)
				
			surftool.add_index(vert + xSize + 1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + xSize + 2)
			vert += 1
		vert += 1
	
	# Generate normals and commit the mesh
	surftool.generate_normals()
	a_mesh = surftool.commit()

	# Set up the MeshInstance3D to display the mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = a_mesh
	add_child(mesh_instance)  # Add MeshInstance3D as a child of StaticBody3D

	# Create the collision shape for the terrain
	var collision_shape = ConcavePolygonShape3D.new()
	
	# Check if the mesh has surface data
	if a_mesh.get_surface_count() == 0:
		print("Error: Mesh has no surfaces.")
		return
	
	var arrays = a_mesh.surface_get_arrays(0)  # Get the vertex data and indices
	
	if arrays == null:
		print("Error: Mesh surface arrays are null.")
		return
	
	# Prepare the collision shape data
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	
	if vertices.size() == 0 or indices.size() == 0:
		print("Error: Vertex or index data is missing.")
		return
	
	var triangle_faces = PackedVector3Array()
	for i in indices:
		triangle_faces.append(vertices[i])

	collision_shape.data = triangle_faces

	# Create the CollisionShape3D node and add it as a child of StaticBody3D
	var shape_node = CollisionShape3D.new()
	shape_node.shape = collision_shape
	add_child(shape_node)
