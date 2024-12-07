extends Node

# Variables for the terrain generation
var size_depth : int = 20
var size_width : int = 20
var HEIGHT_SCALE : int = 50
@export var high_resolution : int = 2
@export var medium_resolution : int = 2
@export var low_resolution : int = 2
@export var max_detail_distance : float = 1.0
@export var mid_detail_distance : float = 2.0

@export var height : FastNoiseLite
@export var moisture : FastNoiseLite

@export var textureGrass : Texture
@export var textureDesert : Texture
@export var textureSnow : Texture

@export var mymaterial : Material

const CHUNK_SIZE = 20
const RENDER_DISTANCE = 4

# Dictionary for storing chunks: key = chunk position (Vector2), value = chunk instance
var loaded_chunks = {}
var last_player_chunk_pos = Vector2(-100, -100)
var update_interval = 0.5
var time_since_last_update = 0.0

var thread_pool = []
var chunk_queue = []
var mutex = Mutex.new()

func _ready():
	var player_pos = get_parent().get_node("PlayerMovement").global_transform.origin
	var chunk_pos = Vector2(int(player_pos.x / CHUNK_SIZE), int(player_pos.z / CHUNK_SIZE))
	update_chunks(chunk_pos)

func _process(delta):
	time_since_last_update += delta
	
	if time_since_last_update >= update_interval:
		var player_pos = get_parent().get_node("PlayerMovement").global_transform.origin
		var chunk_pos = Vector2(int(player_pos.x / CHUNK_SIZE), int(player_pos.z / CHUNK_SIZE))
		
		if chunk_pos != last_player_chunk_pos:
			update_chunks(chunk_pos)
			last_player_chunk_pos = chunk_pos
		
		time_since_last_update = 0.0

	# Process finished threads
	check_thread_results()

# Update the chunks based on the player's position
func update_chunks(player_chunk_pos: Vector2):
	var chunks_to_load = []
	var chunks_to_unload = []

	# Load chunks within render distance
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk = Vector2(player_chunk_pos.x + x, player_chunk_pos.y + z)

			if not loaded_chunks.has(chunk):  # Check if chunk is already loaded
				chunks_to_load.append(chunk)
			else:
				# Update resolution of already loaded chunks
				var chunk_instance = loaded_chunks[chunk]
				var distance = chunk.distance_to(player_chunk_pos)
				var resolution = determine_resolution(distance)

				if chunk_instance.get("resolution") != resolution:
					chunks_to_unload.append(chunk)  # Mark for unloading

	# Unload chunks that are marked (but don't unload too close to the player)
	for chunk in chunks_to_unload:
		if chunk.distance_to(player_chunk_pos) > RENDER_DISTANCE + 1:
			unload_chunk(chunk)

	# Load new chunks asynchronously
	queue_chunks_for_generation(chunks_to_load, player_chunk_pos)

	# Unload chunks outside of render distance (ensure chunks under the player stay loaded)
	for chunk in loaded_chunks.keys():
		if chunk.distance_to(player_chunk_pos) > RENDER_DISTANCE + 1:
			if chunk.y != player_chunk_pos.y:  # Ensure the floor chunk isn't unloaded
				unload_chunk(chunk)

# Queue chunks for generation
func queue_chunks_for_generation(chunks_to_load: Array, player_chunk_pos: Vector2):
	for chunk in chunks_to_load:
		var distance = chunk.distance_to(player_chunk_pos)
		var resolution = determine_resolution(distance)
		
		mutex.lock()
		chunk_queue.append([chunk, resolution])
		mutex.unlock()
		
		# Limit the number of threads to 4 (can be adjusted as needed)
		if thread_pool.size() < 4:
			var thread = Thread.new()
			thread.start(Callable(self, "_threaded_generate_chunks"))
			thread_pool.append(thread)

# Unload a chunk
func unload_chunk(chunk_pos: Vector2):
	if loaded_chunks.has(chunk_pos):
		print("Unloading chunk: ", chunk_pos)
		var chunk = loaded_chunks[chunk_pos]
		chunk.queue_free()  # Free the chunk from memory
		loaded_chunks.erase(chunk_pos)  # Remove from the dictionary
		print("Chunk removed from dictionary: ", chunk_pos)

# Generate a chunk
func _threaded_generate_chunks():
	while true:
		mutex.lock()
		if chunk_queue.is_empty():
			mutex.unlock()
			break  # Exit the thread if no more chunks to generate
		
		var data = chunk_queue.pop_front()
		mutex.unlock()
		
		var chunk_pos = data[0]
		var resolution = data[1]
		var new_chunk = generate(chunk_pos, resolution)
		
		call_deferred("_add_generated_chunk", chunk_pos, new_chunk)

# Add the generated chunk to the scene
func _add_generated_chunk(chunk_pos: Vector2, chunk: MeshInstance3D):
	loaded_chunks[chunk_pos] = chunk
	add_child(chunk)

# Generate mesh for a chunk
func generate(chunk_pos: Vector2 = Vector2(0, 0), resolution: int = 2) -> MeshInstance3D:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * resolution
	plane_mesh.subdivide_width = size_width * resolution
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)

	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		vertex.x += chunk_pos.x * size_width
		vertex.z += chunk_pos.y * size_depth
		vertex.y = height.get_noise_2d(vertex.x, vertex.z) * HEIGHT_SCALE
		data.set_vertex(i, vertex)
	
	array_plane.clear_surfaces()
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = surface.commit()
	mesh_instance.create_trimesh_collision()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	mesh_instance.set("resolution", resolution)
	mesh_instance.add_to_group("NavSource")
	return mesh_instance

# Resolution based on the player's distance to the chunk
func determine_resolution(distance: float) -> int:
	if distance <= max_detail_distance:
		return high_resolution
	elif distance <= mid_detail_distance:
		return medium_resolution
	else:
		return low_resolution

# Check and process finished threads
func check_thread_results():
	for thread in thread_pool:
		if not thread.is_alive():
			thread.wait_to_finish()
			thread_pool.erase(thread)
