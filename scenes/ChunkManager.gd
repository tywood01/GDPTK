extends Node3D

const CHUNK_SIZE = 25  # Make sure this matches your terrain generation size
const RENDER_DISTANCE = 4  # How many chunks around the player to keep loaded

var terrain_chunks = {}
func _process(delta):
	var player_pos = get_node("CharacterBody3D").global_transform.origin
	var chunk_pos = Vector2(int(player_pos.x / CHUNK_SIZE), int(player_pos.z / CHUNK_SIZE))
	update_chunks(chunk_pos)

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
		var new_chunk = generate_terrain(chunk)
		terrain_chunks[chunk] = new_chunk
		add_child(new_chunk)

# Unload chunks that are far from the player
func unload_chunk(chunk_pos: Vector2):
	var chunk = terrain_chunks[chunk_pos]
	chunk.queue_free()
	terrain_chunks.erase(chunk_pos)

# Generate the terrain for a chunk
func generate_terrain(chunk_pos: Vector2) -> StaticBody3D:
	var terrain = StaticBody3D.new()

	# Translate the terrain chunk to the correct world position using chunk size
	terrain.global_transform.origin = Vector3(chunk_pos.x * CHUNK_SIZE, 0, chunk_pos.y * CHUNK_SIZE)

	# Call your existing terrain generation logic here
	var terrain_gen_script = preload("res://scenes/TerrainGen.gd").new()
	terrain.add_child(terrain_gen_script)
	terrain_gen_script.generate_terrain(chunk_pos)

	return terrain
