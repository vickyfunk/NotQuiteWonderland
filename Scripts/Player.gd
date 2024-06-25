extends CharacterBody3D

var speed: float
var sprinting = false
var remaining_dash_duration: float = 0.0
@export var AIR_SPEED = 2.5
@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 10.0
@export var DASH_SPEED = 30.0
const JUMP_VELOCITY = 4.8
@export var SENSITIVITY = 0.004
#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@export var head: Node3D
@export var camera: Camera3D
@export var camera_rotation_amount : float = .085
@export var weapon_holder: Node3D
@export var weapon_sway_amount : float = .05
@export var weapon_rotation_amount : float = .01

@export var bob_amount: float = 0.01
@export var bob_freq: float = 0.01

var mouse_input : Vector2
var default_weapon_holder_pos: Vector3
var dash_dir : Vector3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_weapon_holder_pos = weapon_holder.position
func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		var head_x_rotation = head.rotation.x - event.relative.y * SENSITIVITY
		head_x_rotation = clamp(head_x_rotation, deg_to_rad(-90), deg_to_rad(90))
		head.rotation.x = head_x_rotation
		mouse_input = event.relative

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_just_pressed("sprint"):
		sprinting = not sprinting

	if sprinting:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
	# Get the input direction 
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Initiate dash if just pressed
	if Input.is_action_just_pressed("dash"):
		if direction:
			dash_dir = direction
		else:
			dash_dir = (head.transform.basis * Vector3(0,0,-1)).normalized()
		remaining_dash_duration = 0.1
	
	# Handle the movement/deceleration, and dashing, if relevant.
	if remaining_dash_duration > 0.0:
		velocity.x = dash_dir.x * DASH_SPEED
		velocity.z = dash_dir.z * DASH_SPEED
		remaining_dash_duration -= delta
	else:
		if is_on_floor():
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	head.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
	cam_tilt(input_dir.x, delta)
	weapon_tilt(input_dir.x, delta)
	weapon_sway(delta)
	weapon_bob(velocity.length(), delta)

func cam_tilt(input_x, delta):
	if head:
		head.rotation.z = lerp(head.rotation.z, -input_x * camera_rotation_amount, 10 * delta)

func weapon_tilt(input_x, delta):
	if weapon_holder:
		weapon_holder.rotation.z = lerp(weapon_holder.rotation.z, -input_x * weapon_rotation_amount, 10 * delta)

func weapon_sway(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
	weapon_holder.rotation.x = lerp(weapon_holder.rotation.x, mouse_input.y * weapon_rotation_amount, 15 * delta)
	weapon_holder.rotation.y = lerp(weapon_holder.rotation.y, mouse_input.x * weapon_rotation_amount, 15 * delta)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func weapon_bob(vel: float, delta):
	if weapon_holder:
		if vel > 1:
			weapon_holder.position.y = lerp(weapon_holder.position.y, default_weapon_holder_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
			weapon_holder.position.x = lerp(weapon_holder.position.x, default_weapon_holder_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount, 10 * delta)
		else:
			weapon_holder.position.y = lerp(weapon_holder.position.y, default_weapon_holder_pos.y, 10 * delta)
			weapon_holder.position.x = lerp(weapon_holder.position.x, default_weapon_holder_pos.x, 10 * delta)
