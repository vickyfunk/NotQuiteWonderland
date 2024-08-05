extends CharacterBody3D

signal Update_Velocity

var total_directional_input: Vector3
var speed: float
var sprinting = false
#var remaining_dash_duration: float = 0.0
var jumps_since_grounded: int = 0
#note that AIR_SPEED is currently used for nothing, the effects of drag vs
#friction are what currently makes grounded and in-air motion different
@export var AIR_SPEED = 2.5
@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 10.0
@export var TIME_TO_FULL_SPEED = 0.5
@export var DASH_SPEED = 30.0
@export var DASH_DURATION = 0.1
@export var JUMP_VELOCITY = 4.8
@export var FRICTION = 1.3
@export var DRAG = 0.05
@export var SENSITIVITY = 0.004
#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# An Acc_Ticket stores the remaining acceleration to be imparted from a continual
# acceleration as well as its remaining duration
class Acc_Ticket:
	var acc: Vector3
	var time_to_apply: float
	func _init(_acc: Vector3, _time_to_apply: float = 0.0):
		acc = _acc
		time_to_apply = _time_to_apply

# This is our stack of Acc_Tickets
var acc_tickets: Array[Acc_Ticket] = []


#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

var time_since_step: float
@export var time_bw_steps_walking: float = 0.5
@export var footstep_manager: AudioStreamPlayer3D

@export var character_data: CharacterData
@export var unit_data: UnitData

# The part of the head that rotates horizontally, i.e. around the y axis
@export var horiz_head: Node3D
# The part of the head that rotates vertically, i.e. around the x axis (and tilts)
@export var vert_head: Node3D
@export var camera: Camera3D
@export var camera_rotation_amount : float = .085
@export var weapon_holder: Node3D
@export var weapon_sway_amount : float = .05
@export var weapon_rotation_amount : float = .01

@export var bob_amount: float = 0.01
@export var bob_freq: float = 0.01

@export var Aiming_Crosshair: TextureRect

var mouse_input : Vector2
var default_weapon_holder_pos: Vector3
var dash_dir : Vector3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_weapon_holder_pos = weapon_holder.position
	time_since_step = 0.0

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	#print("get_viewport().get_size()/2=", get_viewport().get_size()/2, ", Vector2i(Aiming_Crosshair.size/2)=", Vector2i(Aiming_Crosshair.size/2))
	#Aiming_Crosshair.position = get_viewport().get_size()/2 #- Vector2i(Aiming_Crosshair.size/2)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		horiz_head.rotate_y(-event.relative.x * SENSITIVITY)
		var head_x_rotation = vert_head.rotation.x - event.relative.y * SENSITIVITY
		head_x_rotation = clamp(head_x_rotation, deg_to_rad(-90), deg_to_rad(90))
		vert_head.rotation.x = head_x_rotation
		mouse_input = event.relative

func _physics_process(delta):
	
	# Add time since last footstep sound, up to 2 seconds past the "time between" value as
	# that is realistically more than enough even if the frequency varies with velocity
	#print("time_since_step: ", time_since_step)
	if time_bw_steps_walking - time_since_step > -2.0:
		time_since_step += delta
		#print("time_since_step update: ", time_since_step)
	
	# Add the gravity.
	if not is_on_floor():
		#velocity.y -= gravity * delta
		queue_accelerate(Vector3.DOWN * gravity * delta)
	else:
		jumps_since_grounded = 0

	# Handle Jump, including allowing for double jump if player has upgrade
	if Input.is_action_just_pressed("jump"):
		# Should you be able to single jump in the air if you walk off an edge and don't have dbl jump?
		# I concluded yes
		# I also figured that this should be a case where player input can zero out prior momentum
		# in a direction
		if jumps_since_grounded < 1 + (character_data.upgrades.double_jump as int):
			#velocity.y = JUMP_VELOCITY
			var jump_vector = Vector3.UP * JUMP_VELOCITY
			if velocity.y < 0:
				jump_vector += Vector3.DOWN * velocity.y
			queue_accelerate(jump_vector)
			jumps_since_grounded += 1
	
	# Handle Sprint.
	if Input.is_action_just_pressed("sprint"):
		sprinting = not sprinting

	if sprinting:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction 
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (horiz_head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Initiate dash if just pressed
	# Todo: 
	# [x] done! add check for is_on_floor() if player doesn't have air dash upgrade
	# [x] done! account for the possibility of player looking straight vertically
	# [ ] figure out some way to limit the amount dash can be spammed serially, for obvious reasons 
	#     (infinite velocity machine)
	if Input.is_action_just_pressed("dash"):
		if character_data.upgrades.air_dash or is_on_floor():
			if direction:   
				# i.e. if a direction is inputted
				dash_dir = direction
			else:   
				# default to the (flat) direction the camera is aiming
				dash_dir = (horiz_head.transform.basis * Vector3(0,0,-1)).normalized()
			#remaining_dash_duration = 0.1
			queue_accelerate(dash_dir * DASH_SPEED, DASH_DURATION)
	
	#var directional_input_difference = direction * speed - total_directional_input
	#var net_di = directional_input_difference * directional_input_difference.length()  * delta
	#total_directional_input += net_di
	var net_di = direction * speed * delta
	queue_accelerate(net_di)
	
	# temporary acc_tickets stack for holding tickets we want to push back on the master stack
	# to avoid using overly costly pop_front() and push_front() 
	var temp_acc_tickets: Array[Acc_Ticket] = []
	
	# go through the acc_tickets stack and apply each one with accelerate(ticket, delta)
	# while using accelerate's return value to determine if the ticket should go back on the stack
	for i in acc_tickets.size():
		var ticket = acc_tickets.pop_back()
		
		# if this Acc_Ticket's time_to_apply is 0'd out (meaning true_delta==ticket.time_to_apply)
		# then the ticket is finished and gets dumped. otherwise, push it to the temporary stack
		if accelerate(ticket, delta):
			temp_acc_tickets.push_back(ticket)
	
	# put the tickets back on the stack!
	for i in temp_acc_tickets.size():
		acc_tickets.push_back(temp_acc_tickets.pop_back())
		
	# Handle the movement/deceleration, and dashing, if relevant.
	# Todo:
	# [x] solved! fix the "aiming more vertically makes you move slower" issue
	# [ ] try to refactor to make this more "additively physics based" i.e. create a velocity summation system
	#if remaining_dash_duration > 0.0:
	#	#velocity.x = dash_dir.x * DASH_SPEED
	#	#velocity.z = dash_dir.z * DASH_SPEED
	#	velocity.x += dash_dir.x * DASH_SPEED * delta * 10.0
	#	velocity.z += dash_dir.z * DASH_SPEED * delta * 10.0
	#	remaining_dash_duration -= delta
	#else:
	
	# The below equation is based on the one for drag irl, with the full equation
	# being the same but multiplied by velocity.length()
	var friction_vector = -velocity.normalized() * FRICTION * delta
	var drag_vector = -velocity * velocity.length() * DRAG * delta

	if is_on_floor():
		#velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
		#velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		
		#figure out how long we should wait between step soundds, scaled inverse to speed, 
		#with hard clamp limits of 0.1 minimum and 2.0 maximum
		var time_bw_steps_current = clamp(time_bw_steps_walking * WALK_SPEED / Vector2(velocity.x,velocity.z).length(), 0.1, 2.0)
		#print("time_bw_steps_current: ", time_bw_steps_current)
		
		#see if we are still moving while on the ground and if enough time has elapsed since 
		#last footstep sound, scaled to current speed. If so, play footstep sound
		if direction:
			var dot_product = direction.dot(velocity.normalized())
			if dot_product < 0.0:
				#queue_accelerate(velocity * dot_product * 4.0 * delta)
				queue_accelerate(-velocity.length() * direction * dot_product * 4.0 * delta)
			if time_bw_steps_current - time_since_step <= 0.0:
				footstep_manager.play()
				time_since_step = 0.0
		else:
			queue_accelerate(-velocity*2.0*delta)
		
	else:
		friction_vector *= 0.0
		#velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		#velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	print("friction_vector: ", friction_vector, ", length = ", friction_vector.length())
	print("drag_vector: ", drag_vector, ", length = ", drag_vector.length())
	var resistance_vector = friction_vector + drag_vector
	print("resistance_vector: ", resistance_vector, ", length = ", resistance_vector.length())
	var resistance_ratio = velocity.length() / resistance_vector.length()
	print("resistance_ratio: ", resistance_ratio)
	# this resistance_ratio conditional multiplication ensures that if the resistance ends up 
	# larger than even the velocity vector it will do no more than neutralize all velocity entirely
	resistance_vector *= resistance_ratio if resistance_ratio < 1.0 else 1.0
	print("final resistance_vector: ", resistance_vector, ", length = ", resistance_vector.length())
	queue_accelerate(resistance_vector)
	
	#velocity *= 0.0 if velocity.length() < 0.3 else 1.0
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	horiz_head.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Update velocity HUD element (debug tool)
	emit_signal("Update_Velocity", velocity.length())
	
	move_and_slide()
	cam_tilt(input_dir.x, delta)
	weapon_tilt(input_dir.x, delta)
	weapon_sway(delta)
	weapon_bob(velocity.length(), delta)

func cam_tilt(input_x, delta):
	if vert_head:
		vert_head.rotation.z = lerp(vert_head.rotation.z, -input_x * camera_rotation_amount, 10 * delta)

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

# acc should be relative acceleration
# time_to_apply is how long it should take to apply the full acceleration,
# leave time_to_apply blank if you want instant acceleration (it will call accelerate right then 
# and there) without waiting for the queue to go through
# make acc be null length to have it do nothing automatically
func queue_accelerate(acc: Vector3, time_to_apply: float = 0.0):
	if acc:
		var ticket = Acc_Ticket.new(acc, time_to_apply)
		if ticket.time_to_apply:
			acc_tickets.push_back(ticket)
		else:
			accelerate(ticket)

# returns true if the ticket should be pushed back onto the ticket stack
func accelerate(ticket: Acc_Ticket, delta: float = 0.0) -> bool:
	if ticket.time_to_apply:
		var true_delta = min(delta, ticket.time_to_apply)
		var acc_to_impart = true_delta / ticket.time_to_apply * ticket.acc
		velocity += acc_to_impart
		ticket.acc -= acc_to_impart
		ticket.time_to_apply -= true_delta
	# i.e. if instantaneous
	else:
		velocity += ticket.acc
		
	return ticket.time_to_apply
