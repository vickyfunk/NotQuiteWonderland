extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var Animation_Player = get_node("AnimationPlayer")
@onready var Bullet_Point = get_node("%Bullet_Point")

var Current_Weapon = null
var Weapon_Stack = [] #array of weapons held by player currently
var Weapon_Indicator = 0 #keeps track of array position
var Next_Weapon: String
var Weapon_List = {}
var Debug_Bullet = preload("res://Assets/World Objects/bullet_debug.tscn")
var mouse_mov_x
var mouse_mov_y
var sway_threshold = 5
var sway_lerp = 5

@export var _weapon_resources: Array[Weapon_Resource]
@export var Start_Weapons: Array[String] #weapons you start with

enum {NULL, HITSCAN, PROJECTILE}

var Collision_Exclusion = []

@export var sway_up : Vector3
@export var sway_down : Vector3
@export var sway_left : Vector3
@export var sway_right : Vector3
@export var sway_default : Vector3
# Called when the node enters the scene tree for the first time.


func _ready():
	Initialize(Start_Weapons)

func Initialize(_start_weapons: Array):
	#creates dictionary of weapons
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	for i in _start_weapons:
		Weapon_Stack.push_back(i)
	Current_Weapon = Weapon_List[Weapon_Stack[0]] #sets 1st weapon in stack to current
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	for i in get_children(): #Hides the weapons even if left visible in the editor
		if i is Node3D:
			i.visible = false
	enter()

func enter():
	Animation_Player.queue(Current_Weapon.Draw_Anim)
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

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
		print(Weapon_Indicator)
		exit(Weapon_Stack[Weapon_Indicator])
	if event.is_action_pressed("prev_weapon"):
		Weapon_Indicator = max(Weapon_Indicator-1, 0)
		print(Weapon_Indicator)
		exit(Weapon_Stack[Weapon_Indicator])
	if event.is_action_pressed("reload"):
		reload()
	if event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_released("shoot"):
		release()
# Called every frame. 'delta' is the elapsed time since the previous frame.

func exit(_next_weapon: String):
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Holster_Anim:
			Animation_Player.play(Current_Weapon.Holster_Anim)
			Next_Weapon = _next_weapon

func _process(delta):
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

func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if !Animation_Player.is_playing(): #cant shoot to interrupt anims, also sets firerate to anim rate
			Animation_Player.play(Current_Weapon.Shoot_Anim)
			Current_Weapon.Current_Ammo -= 1
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			var Camera_Collision = Get_Camera_Collision()
			match Current_Weapon.Type:
				NULL:
					print("Weapon Type Not Chosen")
				HITSCAN:
					Hitscan_Collision(Camera_Collision)
				PROJECTILE:
					Launch_Projectile(Camera_Collision)
	else: 
		reload()

func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			Animation_Player.play(Current_Weapon.Reload_Anim)
			var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo, Current_Weapon.Magazine, Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo + Reload_Amount
			Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo - Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

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
	var Bullet_Direction = (Collision_Point - Bullet_Point.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.get_global_transform().origin, Collision_Point+Bullet_Direction*2)
	
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collision:
		var Hit_Indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(Hit_Indicator)
		Hit_Indicator.global_translate(Bullet_Collision.position)
		
		Hitscan_Damage(Bullet_Collision.collider)
		

func Hitscan_Damage(Collider):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(Current_Weapon.Damage)

func Launch_Projectile(Point: Vector3):
	var Direction = (Point - Bullet_Point.get_global_transform().origin).normalized()
	var Projectile = Current_Weapon.Projectile_to_Load.instantiate()
	var Projectile_RID = Projectile.get_rid()
	Collision_Exclusion.push_front(Projectile_RID)
	Projectile.tree_exited.connect(Remove_Exclusion.bind(Projectile.get_rid()))
	Bullet_Point.add_child(Projectile)
	Projectile.Damage = Current_Weapon.Damage
	Projectile.set_linear_velocity(Direction*Current_Weapon.Projectile_Velocity)

func Remove_Exclusion(Projectile_RID):
	Collision_Exclusion.erase(Projectile_RID)

func release():
	if !Animation_Player.is_playing():
		Animation_Player.play(Current_Weapon.Idle_Anim)

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
