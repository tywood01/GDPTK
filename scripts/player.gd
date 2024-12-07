extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var look_dir: Vector2
var camera_sens = 50
var capMouse    = false
var sensitivity = 0.005
@onready var camera = $Camera3D

# Delay timer before the player can move
var delay_timer = 1  # 0.5 second delay before allowing movement

func _ready():
	# Start the timer
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	delay_timer = 1  # Set the initial delay timer

func _physics_process(delta):
	# Reduce the delay timer
	delay_timer -= delta
	
	# If the timer hasn't finished, prevent movement
	if delay_timer > 0:
		return  # Do nothing until the timer is up

	# Allow movement after the delay timer is up
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Handle pause and mouse visibility toggle
	if Input.is_action_just_pressed("pause"):
		capMouse = !capMouse
		if capMouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	move_and_slide()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
