extends Resource

class_name Weapon_Resource

enum Weapon_Action {Automatic, Manual}

@export_group ("Animations")
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

@export_group ("Audio")
@export var Shoot_Sound: AudioStream
@export var Reload_Sound_1: AudioStream
@export var Reload_Sound_2: AudioStream
@export var Slide_Rack_Sound: AudioStream

#values pulled from the ammo table
@export_group("Firing")
@export_flags("Hitscan", "Projectile") var Type
@export var Caliber: Array #what shape of bullet
@export var Ammo_Type: Array #what kind of bullet of a given caliber
@export var Damage: float #duh
@export var Impact: float #damage dealt to targets not-penetrated by round, determines physics impulse
@export var Wound_Channel: float #determines rate of blood loss
@export var Pen_Rating: float
@export var Auto_Fire: bool #does it full auto or no
@export var Manual_Action: bool #do you have to cock/pump weapon after shooting, same button as bolt release
@export var Weapon_Range: int #max distance b4 projectile despawns
@export var Effective_Range: Curve #distance before damage dropoff
@export var alt_fire_index: int
@export var alt_fire: Callable

#values pulled from magazine table
@export_group("Magazines")
@export var Reloadable: bool #do u need to reload
@export var Platform: String #which magazine is loaded into the weapon
@export var Loaded_Mag: int
@export var Current_Ammo: int #ammo currently in magazine
@export var Capacity: int #maximum magazine capacity, "current magazine.capacity"
@export var Mags_Remaining: int #remaining mags on player's rig
@export var Reserve_Ammo: int #ammo in reserve accross all magazines used by weapon
@export var Needs_Battery: bool #does the weapon use a battery
@export var Current_Charge: float #charge left in battery 
@export var Batteries_Remaining: int #how many batteries do u have

@export_group("Effects")
@export var Projectile_to_Load: PackedScene 
@export var Projectile_Velocity: float
@export var Casing_to_Load: PackedScene
@export var Casing_Eject_Angle: Vector3
@export var Casing_Velocity: int 

@export_group("Control")
@export var Recoil_Lerp_Speed: float = 1.5
@export var Handling: float = 1.0 #swiftness of barrel pointing where you want it to
@export var MOA: float #IMPLEMENT MINOR BULLET DEVIATIONS, NOT BASED ON ANYTHING BUT BARREL QUALITY
@export var Controllable_Burst: int #how many shots until alice stops being highly accurate in one burst, resets on letting go of trigger
@export var Screen_Shake_Intensity: float
@export var recoil_rotation_x: Curve
@export var recoil_rotation_z: Curve
@export var recoil_position_z: Curve
@export var recoil_amplitude := Vector3(1,1,1)
@export var max_z_travel: float
