extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var look_dir: Vector2
var camera_sens = 50
var capMouse    = false
@onready var camera_3d = $Camera3D


	
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if Input.is_action_just_pressed("pause"):
		capMouse = !capMouse
		
		if capMouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_rotate_camera(delta)
	move_and_slide()

func _input(event: InputEvent):
	if event is InputEventMouseMotion: look_dir = event.relative * 0.01
	
	if Input.is_action_just_pressed("quit"):
		$"../".exit_game(name.to_int())
		get_tree().quit()
	
func _rotate_camera(delta: float, sens_mod: float = 1.0):
		var input = Input.get_vector("look_left", "look_right", "look_down", "look_up")
		look_dir += input
		rotation.y -= look_dir.x *camera_sens * delta
		camera_3d.rotation.x = clamp(camera_3d.rotation.x -look_dir.y *camera_sens * sens_mod * delta, -1.5, 1.5)
		look_dir = Vector2.ZERO
		
