class_name TerrainGeneration
extends Node

var mesh : MeshInstance3D
var size_depth : int = 20
var size_width : int = 20
var HEIGHT_SCALE : int = 50
@export var high_resolution : int = 4  # Highest resolution for nearby chunks
@export var medium_resolution : int = 2  # Medium resolution for mid-range chunks
@export var low_resolution : int = 0.5  # Lowest resolution for far chunks
@export var max_detail_distance : float = 1.0  # Distance to use high resolution
@export var mid_detail_distance : float = 2.0  # Distance to use medium resolution

@export var height : FastNoiseLite
@export var moisture : FastNoiseLite

@export var textureGrass : Texture
@export var textureDesert : Texture
@export var textureSnow : Texture

@export var mymaterial : Material

const CHUNK_SIZE = 20  # Ensure this matches your terrain generation size
const RENDER_DISTANCE = 4  # How many chunks around the player to keep loaded

var terrain_chunks = {}
var last_player_chunk_pos = Vector2(-100, -100)  # Store the last chunk position
var update_interval = 0.5  # Throttle updates to every 0.5 seconds
var time_since_last_update = 0.0

class Quadtree:
	var chunks = {}
	
	func insert(chunk_pos: Vector2, chunk):
		chunks[chunk_pos] = chunk
	
	func get_chunk(chunk_pos: Vector2):
		return chunks.get(chunk_pos, null)
	
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
		
		if chunk_pos != last_player_chunk_pos:
			update_chunks(chunk_pos)
			last_player_chunk_pos = chunk_pos
		
		time_since_last_update = 0.0

func update_chunks(player_chunk_pos: Vector2):
	var chunks_to_load = []
	var chunks_to_unload = []
	
	# Load chunks within render distance
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk = Vector2(player_chunk_pos.x + x, player_chunk_pos.y + z)

			if not quadtree.get_chunk(chunk):
				chunks_to_load.append(chunk)
			else:
				# Update resolution of already loaded chunks
				var chunk_instance = quadtree.get_chunk(chunk)
				var distance = chunk.distance_to(player_chunk_pos)
				var resolution = determine_resolution(distance)
				
				if chunk_instance.get("resolution") != resolution:
					chunks_to_unload.append(chunk)  # Mark for unloading
					chunks_to_load.append(chunk)  # Mark for loading a new one

	# Unload chunks that are marked
	for chunk in chunks_to_unload:
		unload_chunk(chunk)

	# Load new chunks
	load_chunks(chunks_to_load, player_chunk_pos)

	# Unload chunks outside of render distance
	var loaded_chunks = quadtree.get_loaded_chunks()
	for chunk in loaded_chunks:
		if chunk.distance_to(player_chunk_pos) > RENDER_DISTANCE:
			unload_chunk(chunk)

func load_chunks(chunks_to_load: Array, player_chunk_pos: Vector2):
	var player_pos = get_parent().get_node("PlayerMovement").global_transform.origin
	
	for chunk in chunks_to_load:
		var distance = chunk.distance_to(player_chunk_pos)
		var resolution = determine_resolution(distance)
		var new_chunk = generate(chunk, resolution)
		quadtree.insert(chunk, new_chunk)
		add_child(new_chunk)

func unload_chunk(chunk_pos: Vector2):
	var chunk = quadtree.get_chunk(chunk_pos)
	if chunk:
		chunk.queue_free()
		quadtree.remove(chunk_pos)

func generate(chunk_pos: Vector2 = Vector2(0, 0), resolution: int = 2):
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
	
	mesh_instance.set("resolution", resolution)  # Store the resolution for later checks
	mesh_instance.add_to_group("NavSource")
	return mesh_instance

func determine_resolution(distance: float) -> int:
	if distance <= max_detail_distance:
		return high_resolution
	elif distance <= mid_detail_distance:
		return medium_resolution
	else:
		return low_resolution
