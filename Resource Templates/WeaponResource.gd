extends Resource

class_name Weapon_Resource

@export var Weapon_Name: String
@export var Idle_Anim: String
@export var Shoot_Anim: String
@export var Reload_Anim: String
@export var Tacload_Anim: String
@export var Draw_Anim: String
@export var Holster_Anim: String
@export var Empty_Anim: String
@export var ADS_Anim: String
@export var DeADS_Anim: String

@export var Shoot_Sound: AudioStream
@export var Reload_Sound_1: AudioStream
@export var Reload_Sound_2: AudioStream
@export var Slide_Rack_Sound: AudioStream

@export var Current_Ammo: int #ammo currently in magazine
@export var Reserve_Ammo: int #ammo in reserve
@export var Magazine: int #magazine capacity
@export var Max_Ammo: int #maximum reserve ammo

@export var Damage: float #duh
@export var Impact: float
@export var Pen_Rating: float

@export var Auto_Fire: bool #does it full auto or no
@export var Weapon_Range: int
@export_flags("Hitscan", "Projectile") var Type
@export var Projectile_to_Load: PackedScene 
@export var Projectile_Velocity: float
@export var Casing_to_Load: PackedScene
@export var Casing_Velocity: int 

@export var Handling: float = 1.0
@export var Shots_Until_Controlled: int = 5 #how many shots experience "normal" recoil before Alice has the gun under control?

@export var Screen_Shake_Intensity: float
@export var recoil_rotation_x: Curve
@export var recoil_rotation_z: Curve
@export var recoil_position_z: Curve
@export var recoil_amplitude := Vector3(1,1,1)
@export var max_z_travel: float

@export var alt_fire_index: int
