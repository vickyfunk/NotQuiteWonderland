extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var Animation_Player = get_node("AnimationPlayer")
@onready var Bullet_Point = get_node("%Bullet_Point")
@onready var Aiming_Point = get_node("%Bullet_Point/Aiming_Point")

@export var shoot_audio_player: AudioStreamPlayer3D
@export var reload_audio_player: AudioStreamPlayer3D
@export var Tracer: MeshInstance3D
@export var vert_head: Node3D
@export var wrist: Node3D
@export var camera_shaker: CameraShaker
@export var recoil_lerp_speed: float = 1

var empty_reload: bool = false

var target_rot: Vector3
var target_pos: Vector3
var z_travel: float
var max_z_travel: float
var current_time: float
var z_position_prerecoil
var x_rotation_prerecoil

var Current_Weapon = null
var Weapon_Stack = [] #array of weapons held by player currently
var Weapon_Indicator = 0 #keeps track of array position
var Next_Weapon: String
var Weapon_List = {}
var Debug_Bullet = preload("res://Assets/World Objects/bullet_debug.tscn")
@onready var Generic_Bullet = preload("res://Scenes/9x19bullet.tscn")
var mouse_mov_x
var mouse_mov_y
var sway_threshold = 5
var sway_lerp = 5

var shots_in_burst: int = 0
var time_since_release: float = 0.16

@export var _weapon_resources: Array[Weapon_Resource]
@export var Start_Weapons: Array[String] #weapons you start with

enum {NULL, HITSCAN, PROJECTILE}

var Collision_Exclusion = []
@export var gun_barrel_crosshair: TextureRect
@export var camera: Camera3D

@export var sway_up : Vector3
@export var sway_down : Vector3
@export var sway_left : Vector3
@export var sway_right : Vector3
@export var sway_default : Vector3
# Called when the node enters the scene tree for the first time.


func _ready():
	Initialize(Start_Weapons)
	target_rot.y = rotation.y
	current_time = 1

func Initialize(_start_weapons: Array):
	#creates dictionary of weapons
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	for i in _start_weapons:
		Weapon_Stack.push_back(i)
	Current_Weapon = Weapon_List[Weapon_Stack[0]] #sets 1st weapon in stack to current
	
	#stinky ad hoc line to try and get the bullet to show up!
	#Current_Weapon.Projectile_to_Load = Generic_Bullet
	
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	for i in get_children(): #Hides the weapons even if left visible in the editor
		if i is Node3D:
			i.visible = false
	enter()

func enter():
	Animation_Player.queue(Current_Weapon.Draw_Anim)
	shoot_audio_player.stream = Current_Weapon.Shoot_Sound
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	max_z_travel = Current_Weapon.max_z_travel

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov_x = -event.relative.x
		mouse_mov_y = -event.relative.y
	if event.is_action_pressed("free_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else: 
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("next_weapon"):
		Weapon_Indicator = min(Weapon_Indicator+1, Weapon_Stack.size()-1)
		#print(Weapon_Indicator)
		exit(Weapon_Stack[Weapon_Indicator])
	if event.is_action_pressed("prev_weapon"):
		Weapon_Indicator = max(Weapon_Indicator-1, 0)
		#print(Weapon_Indicator)
		exit(Weapon_Stack[Weapon_Indicator])
	if event.is_action_pressed("reload"):
		reload()
	if event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_released("shoot"):
		release()

func exit(_next_weapon: String):
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Holster_Anim:
			Animation_Player.play(Current_Weapon.Holster_Anim)
			Next_Weapon = _next_weapon

func _process(delta):
	if max_z_travel > 0: #I.e. if our gun is not "recoilless"
		if current_time < 0.32: #I.e. if it's been less than .32 seconds since we fired the gun
			current_time += delta
			position.z = lerp(position.z, target_pos.z, recoil_lerp_speed * delta) if abs(z_travel) <= Current_Weapon.max_z_travel else position.z
			#Offset the Aiming_Point on the z axis by precisely how far the gun has kicked back so far
			Aiming_Point.position.z = -z_position_prerecoil
			z_travel = z_position_prerecoil - position.z
			rotation.z = lerp(rotation.z, target_rot.z, recoil_lerp_speed * delta)
			#doubled recoil_lerp_speed here to make the x kick snappier in the time we have
			#also made this one be head rotation specifically so you get camera kick
			#Todo: make this also have some element of pure gun kick
			wrist.rotation.x = lerp(wrist.rotation.x, target_rot.x, 2 * recoil_lerp_speed * delta)
			#vert_head.rotation.x = lerp(vert_head.rotation.x, target_rot.x, 2 * recoil_lerp_speed * delta)
			#rotation.x = lerp(rotation.x, target_rot.x, 2 * recoil_lerp_speed * delta)
			
			target_rot.z = Current_Weapon.recoil_rotation_z.sample(current_time) * Current_Weapon.recoil_amplitude.y
			target_rot.x = wrist.rotation.x + Current_Weapon.recoil_rotation_x.sample(current_time) * Current_Weapon.recoil_amplitude.x * (1.0 if shots_in_burst < Current_Weapon.Shots_Until_Controlled else 0.1)
			#target_rot.x = vert_head.rotation.x + Current_Weapon.recoil_rotation_x.sample(current_time) * Current_Weapon.recoil_amplitude.x
			#target_rot.x = rotation.x + Current_Weapon.recoil_rotation_x.sample(current_time) * Current_Weapon.recoil_amplitude.x
			target_pos.z = Current_Weapon.recoil_position_z.sample(current_time) * Current_Weapon.recoil_amplitude.z if abs(z_travel) <= max_z_travel else z_position_prerecoil - max_z_travel
		else:
			
			if z_position_prerecoil:
				if abs(z_position_prerecoil - position.z) < 0.01:
					z_position_prerecoil = null
				else:
					position.z = lerp(position.z, z_position_prerecoil, 20 * delta)
					Aiming_Point.position.z = -z_position_prerecoil
		
		if current_time > 0.2:
			wrist.rotation.x = lerp(wrist.rotation.x, 0.0, Current_Weapon.Handling * delta)	
		if Input.is_action_pressed("shoot"):
			time_since_release = 0.0
		if time_since_release < 0.1:
			time_since_release += delta
		elif shots_in_burst > 0:
			shots_in_burst -= 1
			time_since_release = 0.0
			




	var sway_final : Vector3 = sway_default
	if mouse_mov_x != null:
		if mouse_mov_x > sway_threshold:
			sway_final += sway_left
		elif mouse_mov_x < -sway_threshold:
			sway_final += sway_right
	if mouse_mov_y != null:
		if mouse_mov_y > sway_threshold:
			sway_final += sway_up
		elif mouse_mov_y < -sway_threshold:
			sway_final += sway_down
	rotation = rotation.lerp(sway_final, sway_lerp * delta)
	 
	gun_barrel_crosshair.position = camera.unproject_position(get_barrel_collision()) - gun_barrel_crosshair.size/2

func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if !Animation_Player.is_playing(): #cant shoot to interrupt anims, also sets firerate to anim rate
			shoot_audio_player.play()
			Animation_Player.play(Current_Weapon.Shoot_Anim)
			Current_Weapon.Current_Ammo -= 1
			shots_in_burst += 1 if shots_in_burst < Current_Weapon.Shots_Until_Controlled else 0
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			#var Camera_Collision = Get_Camera_Collision()
			var Barrel_Collision = get_barrel_collision()
			apply_recoil(Current_Weapon.Screen_Shake_Intensity)
			match Current_Weapon.Type:
				NULL:
					print("Weapon Type Not Chosen")
				HITSCAN:
					Hitscan_Collision(Barrel_Collision)
				PROJECTILE:
					Launch_Projectile(Barrel_Collision)
	else: 
		reload()

func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			Animation_Player.play(Current_Weapon.Reload_Anim)
			
			empty_reload = Current_Weapon.Current_Ammo == 0
			reload_audio_player.stream = Current_Weapon.Reload_Sound_1
			reload_audio_player.play()
			
			var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo, Current_Weapon.Magazine, Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo + Reload_Amount
			Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo - Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

#todo: make this do something
func tacload():
	pass

func Get_Camera_Collision()->Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2)*Current_Weapon.Weapon_Range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	New_Intersection.set_exclude(Collision_Exclusion)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Col_Point = Intersection.position
		return Col_Point
	else:
		return Ray_End

func Hitscan_Collision(Collision_Point):
	if Collision_Point:
		pass
		#print("Collision_Point is %s, trying to init tracer" % Collision_Point)
		#print("Bullet_Point is %s" % Bullet_Point.get_global_transform().origin)
		#Tracer.draw_tracer(Bullet_Point.get_global_transform().origin, Collision_Point)
	var Bullet_Direction = (Collision_Point - Bullet_Point.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.get_global_transform().origin, Collision_Point+Bullet_Direction*2)
	
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collision:
		var Hit_Indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(Hit_Indicator)
		Hit_Indicator.global_translate(Bullet_Collision.position)
		
		Hitscan_Damage(Bullet_Collision.collider, Bullet_Direction, Bullet_Collision.position)
		

func Hitscan_Damage(Collider, Direction, Position):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(Current_Weapon.Damage, Direction, Position)

func Launch_Projectile(Point: Vector3):
	var Direction = (Point - Bullet_Point.get_global_transform().origin).normalized()
	var Projectile = Current_Weapon.Projectile_to_Load.instantiate()
	#var Projectile = Generic_Bullet.instantiate()
	Projectile.is_player_bullet = true
	var Projectile_RID = Projectile.get_rid()
	Collision_Exclusion.push_front(Projectile_RID)
	Projectile.tree_exited.connect(Remove_Exclusion.bind(Projectile.get_rid()))
	get_tree().current_scene.add_child(Projectile)
	Projectile.transform = Bullet_Point.global_transform
	Projectile.Damage = Current_Weapon.Damage
	#unsure if switching to impulses actually broke it but I rewrote the original code anyway and it definitely works
	Projectile.set_linear_velocity(Direction * Current_Weapon.Projectile_Velocity)

func Remove_Exclusion(Projectile_RID):
	Collision_Exclusion.erase(Projectile_RID)

func release():
	if !Animation_Player.is_playing():
		Animation_Player.play(Current_Weapon.Idle_Anim)
	time_since_release = 0.0

func Change_Weapon(weapon_name: String):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == Current_Weapon.Holster_Anim:
		Change_Weapon(Next_Weapon)
	if anim_name == Current_Weapon.Shoot_Anim && Current_Weapon.Auto_Fire == true:
		if Input.is_action_pressed("shoot"):
			shoot()
	#if anim_name == Current_Weapon.Reload_Anim:
	#	reload_audio_player.stream = Current_Weapon.Reload_Sound_2
	#	reload_audio_player.play()

func apply_recoil(screen_shake_intensity: float):
	camera_shaker.add_trauma(screen_shake_intensity)
	#print("shots_in_burst: ", shots_in_burst, ", Shots_Until_Controlled: ", Current_Weapon.Shots_Until_Controlled)
	if !z_position_prerecoil:
		z_position_prerecoil = position.z
	z_travel = z_position_prerecoil - position.z
	#print(z_travel)
	if max_z_travel > 0:
		target_rot.z = Current_Weapon.recoil_rotation_z.sample(0)
		target_rot.x = Current_Weapon.recoil_rotation_x.sample(0)
		target_pos.z = Current_Weapon.recoil_position_z.sample(0)
		if abs(z_travel) < max_z_travel:
			target_pos.z = Current_Weapon.recoil_position_z.sample(0)   
			#print("within bounds, target value %s" % target_pos.z)
		else: 
			target_pos.z = z_position_prerecoil - max_z_travel
			#print("out of bounds, capping target value to %s" % target_pos.z)
		current_time = 0
		if shots_in_burst >= Current_Weapon.Shots_Until_Controlled:
			target_rot.x *= 0.1


func _on_reload_player_finished():
	if reload_audio_player.stream == Current_Weapon.Reload_Sound_1:
		reload_audio_player.stream = Current_Weapon.Reload_Sound_2
		reload_audio_player.play()
	elif empty_reload and reload_audio_player.stream == Current_Weapon.Reload_Sound_2:
		empty_reload = false
		reload_audio_player.stream = Current_Weapon.Slide_Rack_Sound
		reload_audio_player.play()

func get_barrel_collision() -> Vector3: 
	#var camera = get_viewport().get_camera_3d()
	var ray_origin = Aiming_Point.get_global_position()
	#var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2)*Current_Weapon.Weapon_Range
	#Get a point our current weapon's range away from the barrel of the gun in the negative z direction of the barrel (forward)
	var ray_end = ray_origin - Aiming_Point.global_transform.basis.z.normalized() * Current_Weapon.Weapon_Range
	var barrel_raycast = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var intersection = get_world_3d().direct_space_state.intersect_ray(barrel_raycast)
	
	if not intersection.is_empty():
		var collision_point = intersection.position
		return collision_point
	else:
		return ray_end
