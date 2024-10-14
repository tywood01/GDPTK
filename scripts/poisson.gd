extends Node2D

var points = []
var active_points = []
var grid = []
var cell_size = 0
var grid_width = 0
var grid_height = 0
var minimum_distance = 0
const MAX_ATTEMPTS = 30

func _ready():
	# Example usage of sampling a rectangle for tree placement
	var top_left = Vector2(0, 0)
	var lower_right = Vector2(1024, 768)
	var min_dist = 50  # Adjust this value for minimum tree separation distance
	points = poisson_disk_sample(top_left, lower_right, min_dist)

	for point in points:
		# You can instantiate trees at these points
		print(point)

func poisson_disk_sample(top_left: Vector2, lower_right: Vector2, min_dist: float) -> Array:
	minimum_distance = min_dist
	cell_size = minimum_distance / sqrt(2)

	# Grid setup
	var dimensions = lower_right - top_left
	grid_width = int(dimensions.x / cell_size) + 1
	grid_height = int(dimensions.y / cell_size) + 1
	grid = []
	for i in range(grid_width):
		grid.append([])
		for j in range(grid_height):
			grid[i].append(null)

	active_points = []
	points = []

	# Start by adding the first random point
	add_first_point(top_left, lower_right)

	# While there are still active points to process
	while active_points.size() > 0:
		var index = randi_range(0, active_points.size() - 1)
		var point = active_points[index]
		var found = false

		# Try to add more points around the current point
		for garbage in range(MAX_ATTEMPTS):
			if add_next_point(point, top_left, lower_right):
				found = true
				break

			# If no point was found, remove from active points
			if not found:
				active_points.remove(index)

	return points

func add_first_point(top_left: Vector2, lower_right: Vector2) -> void:
	var random_point = Vector2(
	randf_range(top_left.x, lower_right.x),
	randf_range(top_left.y, lower_right.y)
	)
	
	var grid_index = get_grid_index(random_point, top_left)
	grid[grid_index.x][grid_index.y] = random_point
	active_points.append(random_point)
	points.append(random_point)

func add_next_point(point: Vector2, top_left: Vector2, lower_right: Vector2) -> bool:
	var new_point = generate_random_around(point)
	
	if new_point.x >= top_left.x and new_point.x < lower_right.x and new_point.y >= top_left.y and new_point.y < lower_right.y:
		
		var grid_index = get_grid_index(new_point, top_left)

		# Check neighbors for proximity
		if not is_too_close(grid_index):
			active_points.append(new_point)
			points.append(new_point)
			grid[grid_index.x][grid_index.y] = new_point
			return true
	return false

func generate_random_around(center: Vector2) -> Vector2:
	var radius = minimum_distance + randf_range(0, minimum_distance)
	var angle = randf_range(0, PI * 2)
	
	return Vector2(
		center.x + radius * cos(angle),
		center.y + radius * sin(angle)
	)

func get_grid_index(point: Vector2, origin: Vector2) -> Vector2:
	return Vector2(
		int((point.x - origin.x) / cell_size),
		int((point.y - origin.y) / cell_size)
	)

func is_too_close(grid_index: Vector2) -> bool:
	for i in range(max(0, grid_index.x - 2), min(grid_width, grid_index.x + 3)):
		for j in range(max(0, grid_index.y - 2), min(grid_height, grid_index.y + 3)):
			if grid[i][j] != null and grid[i][j].distance_to(points.back()) < minimum_distance:
				return true
	return false
