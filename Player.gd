extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

var bullet = load("res://Scenes/Bullet.tscn")
var instance 
var collision_instance

@onready var head = $"Head"
@onready var camera = $"Head/Camera3D"
@onready var camera_rotation_amount : float = .085
@onready var gun = $"Head/Camera3D/Hand/Assault Rifle"
@onready var gun_anim = $"Head/Camera3D/Hand/Assault Rifle/RootNode/AnimationPlayer"
@onready var gun_barrel = $"Head/Camera3D/Hand/Assault Rifle/RootNode/RayCast3D"
@onready var aiming_raycast = $Head/Camera3D/Hand/AimingRaycast

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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
	camera.transform.origin = _headbob(t_bob)
	
	if Input.is_action_pressed("shoot"):
		shoot()
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
	cam_tilt(input_dir.x, delta)

func cam_tilt(input_x, delta):
	if camera:
		camera.rotation.z = lerp(camera.rotation.z, -input_x * camera_rotation_amount, 10 * delta)
	

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func shoot():
	if !gun_anim.is_playing():
		gun_anim.play("Shoot")
		instance = bullet.instantiate()		#The visible bullet shooting out of the gun barrel
		collision_instance = bullet.instantiate()		#The (supposed to be) invisible bullet shooting out from the center of the camera which determines the actual bullet impact location
		collision_instance.is_coll = true	
		
		#Spawn the visible bullet from the gun barrel and make sure it's rotated the correct direction
		instance.position = gun_barrel.global_position
		instance.transform.basis = gun_barrel.global_transform.basis
		instance.rotation.y = gun.global_rotation.y
		
		#Spawn the invisible collision-detection bullet from the center of screen and make sure it's rotated correct
		collision_instance.position = aiming_raycast.global_position
		collision_instance.transform.basis = aiming_raycast.global_transform.basis
		collision_instance.rotation.y = aiming_raycast.global_rotation.y
		
		
		
		get_parent().add_child(instance)
		get_parent().add_child(collision_instance)
		
		collision_instance.ready()

