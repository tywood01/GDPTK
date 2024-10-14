extends Node2D

# Parameters for Poisson disk sampling
@export var max_attempts = 30
@export var point_radius = 2.0

# Define bounds for the area (replace with desired width and height)
@export var width = 500
@export var height = 500

# Seed for random number generation
@export var seed = 1234  # Default seed value, can be changed in the Inspector

# Image for the noise map
var noise_image : Image
@export var noise_texture : ImageTexture  # Exported so it appears in the editor

# Biome definitions
enum BiomeType { DENSE, NORMAL, SPARSE }

# Biome count for ease of access
const BIOME_COUNT = 3  # Number of biome types defined

var biome_map = {}  # To store biome data
var biome_density = {
	BiomeType.DENSE: 1.0,   # Minimum distance for dense biome
	BiomeType.NORMAL: 18.0,  # Minimum distance for normal biome
	BiomeType.SPARSE: 20.0   # Minimum distance for sparse biome
}

# Arrays to store points and active points
@export var points = []
var active_points = []

# Grid for spatial partitioning
var grid = {}
var cell_size = 0.0  # Will be set dynamically based on min_distance

func _ready():
	randomize_with_seed(seed)  # Seed the random number generator
	generate_biome_map()  # Generate the biome map based on the desired distribution
	generate_poisson_noise()

func randomize_with_seed(seed_value):
	RandomNumberGenerator.new().seed = seed_value

func generate_biome_map():
	# Generate a random biome map for demonstration (you can customize this)
	for x in range(width):
		for y in range(height):
			# Randomly assign a biome type
			var biome_type = randi() % BIOME_COUNT  # Use the biome count constant
			biome_map[Vector2(x, y)] = biome_type

func generate_poisson_noise():
	# Initialize the image and texture
	noise_image = Image.create(width, height, false, Image.FORMAT_RGB8)
	noise_image.fill(Color(0, 0, 0))  # Fill with black (empty space)

	# Initialize grid and reset points
	grid.clear()
	points.clear()
	active_points.clear()

	# Start with a random point within custom bounds
	var start_point = Vector2(randi_range(0, width), randi_range(0, height))
	points.append(start_point)
	active_points.append(start_point)
	add_point_to_grid(start_point)

	# Loop until there are no active points
	while active_points.size() > 0:
		# Pick a random active point
		var index = randi() % active_points.size()
		var point = active_points[index]

		var found = false
		# Get the biome type for the current point
		var current_biome = biome_map.get(point, BiomeType.NORMAL)
		var min_distance = biome_density[current_biome]  # Get min_distance based on biome

		# Update the cell size based on the current min_distance
		cell_size = min_distance / sqrt(2.0)

		# Try to generate new points around the current point
		for attempt in range(max_attempts):
			var new_point = generate_random_point_around(point, min_distance)

			# Check if the new point is valid
			if is_valid_point(new_point, min_distance):
				points.append(new_point)
				active_points.append(new_point)
				# Draw the point on the image
				noise_image.set_pixelv(new_point, Color(1, 1, 1))  # White for valid points
				add_point_to_grid(new_point)
				found = true
				break

		# If no valid point was found, remove this active point
		if not found:
			active_points.remove_at(index)

	# Create the texture from the image
	noise_texture = ImageTexture.create_from_image(noise_image)

func generate_random_point_around(center, min_distance):
	var angle = randf_range(0, 2 * PI)
	var distance = randf_range(min_distance, 2 * min_distance)
	return center + Vector2(cos(angle), sin(angle)) * distance

func is_valid_point(point, min_distance):
	# Check if the point is within the bounds of the predefined area
	if point.x < 0 or point.x >= width or point.y < 0 or point.y >= height:
		return false

	# Get grid cell coordinates for this point
	var cell_x = int(point.x / cell_size)
	var cell_y = int(point.y / cell_size)

	# Check neighboring cells in the grid
	for x in range(cell_x - 1, cell_x + 2):
		for y in range(cell_y - 1, cell_y + 2):
			var cell_key = Vector2(x, y)
			if cell_key in grid:
				for existing_point in grid[cell_key]:
					if point.distance_to(existing_point) < min_distance:
						return false

	return true

func add_point_to_grid(point):
	# Calculate the grid cell coordinates for the point
	var cell_x = int(point.x / cell_size)
	var cell_y = int(point.y / cell_size)
	var cell_key = Vector2(cell_x, cell_y)

	# Add the point to the grid
	if not grid.has(cell_key):
		grid[cell_key] = []
	grid[cell_key].append(point)

# This function is used to draw the exported image as a 2D texture
func _draw():
	if noise_texture:
		draw_texture(noise_texture, Vector2(0, 0))
