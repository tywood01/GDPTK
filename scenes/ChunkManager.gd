class_name TerrainGeneration
extends Node

var mesh : MeshInstance3D
var size_depth : int = 20
var size_width : int = 20
var mesh_resolution : int = 0.5
var HEIGHT_SCALE : int = 50

@export var height : FastNoiseLite
@export var moisture : FastNoiseLite

@export var textureGrass : Texture
@export var textureDesert : Texture
@export var textureSnow : Texture

@export var mymatrial : Material

const CHUNK_SIZE = 20  # Ensure this matches your terrain generation size
const RENDER_DISTANCE = 4  # How many chunks around the player to keep loaded

var terrain_chunks = {}
var last_player_chunk_pos = Vector2(-100, -100)  # Store the last chunk position
var update_interval = 0.5  # Throttle updates to every 0.5 seconds
var time_since_last_update = 0.0

# Quadtree class for storing chunks in quadrants
class Quadtree:
	var chunks = {}
	
	func insert(chunk_pos: Vector2, chunk):
		chunks[chunk_pos] = chunk
	
	func get_chunk(chunk_pos: Vector2):
		if chunks.has(chunk_pos):
			return chunks[chunk_pos]
		return null
	
	func remove(chunk_pos: Vector2):
		if chunks.has(chunk_pos):
			chunks.erase(chunk_pos)
	
	func get_loaded_chunks():
		return chunks.keys()

var quadtree = Quadtree.new()

func _process(delta):
	time_since_last_update += delta
	
	if time_since_last_update >= update_interval:
		var player_pos = get_parent().get_node("PlayerMovement").global_transform.origin
		var chunk_pos = Vector2(int(player_pos.x / CHUNK_SIZE), int(player_pos.z / CHUNK_SIZE))
		
		# Only update if the player has moved to a new chunk
		if chunk_pos != last_player_chunk_pos:
			update_chunks(chunk_pos)
			last_player_chunk_pos = chunk_pos
		
		time_since_last_update = 0.0

# Update chunks around the player
func update_chunks(player_chunk_pos: Vector2):
	var chunks_to_load = []

	# Load chunks within render distance
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk = Vector2(player_chunk_pos.x + x, player_chunk_pos.y + z)

			if not quadtree.get_chunk(chunk):
				chunks_to_load.append(chunk)

	load_chunks(chunks_to_load)

	# Unload chunks outside of render distance
	var loaded_chunks = quadtree.get_loaded_chunks()
	for chunk in loaded_chunks:
		if chunk.distance_to(player_chunk_pos) > RENDER_DISTANCE:
			unload_chunk(chunk)

# Load new chunks and generate terrain
func load_chunks(chunks_to_load: Array):
	for chunk in chunks_to_load:
		var new_chunk = generate(chunk)
		quadtree.insert(chunk, new_chunk)
		add_child(new_chunk)

# Unload chunks that are far from the player
func unload_chunk(chunk_pos: Vector2):
	var chunk = quadtree.get_chunk(chunk_pos)
	if chunk:
		chunk.queue_free()
		quadtree.remove(chunk_pos)

# Generate the terrain for a chunk
func generate_terrain(chunk_pos: Vector2) -> MeshInstance3D:
	var terrain = MeshInstance3D
	print(chunk_pos)
	# Translate the terrain chunk to the correct world position using chunk size
	#terrain.global_transform.origin = Vector3(chunk_pos.x * CHUNK_SIZE, 0, chunk_pos.y * CHUNK_SIZE)

	# Call your existing terrain generation logic here

	# Pass the chunk coordinates to the terrain generator if necessary
	# Add terrain generation script to the terrain chunk
	return terrain
func generate(chunk_pos: Vector2 = Vector2(0, 0)):
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * mesh_resolution
	plane_mesh.subdivide_width = size_width * mesh_resolution
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	# Offset vertex positions based on chunk coordinates
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		
		# Apply height noise and offset with chunk coordinates
		vertex.x += chunk_pos.x * size_width
		vertex.z += chunk_pos.y * size_depth
		vertex.y = height.get_noise_2d(vertex.x, vertex.z) * HEIGHT_SCALE
		
		data.set_vertex(i, vertex)
	
	array_plane.clear_surfaces()
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()
	
	mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add navigation to our mesh.
	mesh.add_to_group("NavSource")
	return mesh
