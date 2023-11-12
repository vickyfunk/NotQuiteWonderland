extends CanvasLayer

@onready var CurrentWeaponLabel = $VBoxContainer/HBoxContainer/CurrentWeapon
@onready var CurrentAmmoLabel = $VBoxContainer/HBoxContainer2/CurrentAmmo
@onready var CurrentWeaponStack = $VBoxContainer/HBoxContainer3/WeaponStack
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_weapon_manager_update_ammo(Ammo):
	CurrentAmmoLabel.set_text(str(Ammo[0])+" / "+str(Ammo[1]))


func _on_weapon_manager_update_weapon_stack(Weapon_Stack):
	CurrentWeaponLabel.set_text("")
	for i in Weapon_Stack:
		CurrentWeaponStack.text += "\n"+i


func _on_weapon_manager_weapon_changed(Weapon_Name):
	CurrentWeaponLabel.set_text(Weapon_Name)
