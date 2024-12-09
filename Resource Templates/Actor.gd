extends RigidBody3D

class_name Actor

@export var perception_manager: Perceiver
@export var memory: Array
@export var unit_data: UnitData

func Hit_Successful(Damage, Impact, Pen_Rating, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO):
	var Hit_Position = _Position - get_global_transform().origin
	print("Hit_Position: ", Hit_Position)
	if _Direction != Vector3.ZERO:
		var stumble_impulse = _Direction * (0.1 * Impact)
		print("Applying impulse, magnitude ", stumble_impulse)
		apply_impulse(stumble_impulse, Hit_Position)
	unit_data.take_damage(Damage, Impact, Pen_Rating)
	if unit_data.health <= 0:
		die()

func _ready():
	print("turret initialized")

func die():
	print("aaaaaaaaaaaaa that's me dying")
	queue_free()
