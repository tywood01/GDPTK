extends Node3D

const CHUNK_SIZE = 20  # Ensure this matches your terrain generation size
const RENDER_DISTANCE = 4  # How many chunks around the player to keep loaded

var terrain_chunks = {}
var chunk_heights = {}  # Store heights of generated chunks
var last_player_chunk_pos = Vector2(-100, -100)  # Store the last chunk position
var update_interval = 0.5  # Throttle updates to every 0.5 seconds
var time_since_last_update = 0.0

# Called when the node enters the scene tree for the first time
func _ready():
	# Ensure chunks around the player are generated at the start
	var player_pos = get_node("CharacterBody3D").global_transform.origin
	var chunk_pos = Vector2(int(player_pos.x / CHUNK_SIZE), int(player_pos.z / CHUNK_SIZE))
	last_player_chunk_pos = chunk_pos
	update_chunks(chunk_pos)

# Main update loop to track the player's movement and load/unload chunks
func _process(delta):
	time_since_last_update += delta
	
	if time_since_last_update >= update_interval:
		var player_pos = get_node("CharacterBody3D").global_transform.origin
		var chunk_pos = Vector2(int(player_pos.x / CHUNK_SIZE), int(player_pos.z / CHUNK_SIZE))
		
		# Only update if the player has moved to a new chunk
		if chunk_pos != last_player_chunk_pos:
			update_chunks(chunk_pos)
			last_player_chunk_pos = chunk_pos
		
		time_since_last_update = 0.0

# Update chunks around the player
func update_chunks(player_chunk_pos: Vector2):
	var chunks_to_load = []

	# Check the area around the player for chunks to load
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk = Vector2(player_chunk_pos.x + x, player_chunk_pos.y + z)

			if not terrain_chunks.has(chunk):
				chunks_to_load.append(chunk)

	load_chunks(chunks_to_load)

	# Unload chunks outside of the render distance
	var chunks_to_remove = []
	for chunk in terrain_chunks.keys():
		if chunk.distance_to(player_chunk_pos) > RENDER_DISTANCE:
			chunks_to_remove.append(chunk)

	for chunk in chunks_to_remove:
		unload_chunk(chunk)

# Load new chunks and generate terrain
func load_chunks(chunks_to_load: Array):
	for chunk in chunks_to_load:
		# Determine the base height from adjacent chunks
		var base_height = get_base_height(chunk)
		var new_chunk = generate_terrain(chunk, base_height)
		terrain_chunks[chunk] = new_chunk
		add_child(new_chunk)  # Make sure chunks are added as children

# Unload chunks that are far from the player
func unload_chunk(chunk_pos: Vector2):
	var chunk = terrain_chunks[chunk_pos]
	chunk.queue_free()
	terrain_chunks.erase(chunk_pos)

# Generate the terrain for a chunk
func generate_terrain(chunk_pos: Vector2, base_height: float) -> StaticBody3D:
	var terrain = StaticBody3D.new()
	terrain.global_transform.origin = Vector3(chunk_pos.x * CHUNK_SIZE, 0, chunk_pos.y * CHUNK_SIZE)

	# Create the terrain generation script instance
	var terrain_gen_script = preload("res://scenes/TerrainGen.gd").new()
	
	# Pass the chunk coordinates and base height to the terrain generator
	terrain_gen_script.generate_terrain(chunk_pos, base_height)
	
	# Add terrain generation script to the terrain chunk
	terrain.add_child(terrain_gen_script)
	
	# Store the height for future reference
	chunk_heights[chunk_pos] = base_height
	return terrain

# Function to get the base height from adjacent chunks
func get_base_height(chunk: Vector2) -> float:
	var height_sum = 0.0
	var count = 0

	# Check adjacent chunks: (left, right, top, bottom)
	var adjacent_chunks = [
		chunk + Vector2(-1, 0),  # left
		chunk + Vector2(1, 0),   # right
		chunk + Vector2(0, -1),  # top
		chunk + Vector2(0, 1)     # bottom
	]

	for adj_chunk in adjacent_chunks:
		if chunk_heights.has(adj_chunk):
			height_sum += chunk_heights[adj_chunk]
			count += 1

	# Return the average height of the adjacent chunks, or a default value if none exist
	if count > 0:
		return height_sum / count
	else:
		return 0.0  # Ensure it returns 0.0 when no adjacent heights are found
