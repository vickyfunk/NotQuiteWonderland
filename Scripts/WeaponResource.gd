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

@export var Current_Ammo: int #ammo currently in magazine
@export var Reserve_Ammo: int #ammo in reserve
@export var Magazine: int #magazine capacity
@export var Max_Ammo: int #maximum reserve ammo

@export var Damage: int #duh
@export var Auto_Fire: bool #does it full auto or no
@export var Weapon_Range: int
@export_flags("Hitscan", "Projectile") var Type
@export var Projectile_to_Load: PackedScene 
@export var Projectile_Velocity: int
@export var Casing_to_Load: PackedScene
@export var Casing_Velocity: int 
