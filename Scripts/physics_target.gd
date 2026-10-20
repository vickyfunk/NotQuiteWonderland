extends RigidBody3D

var Health = 500
@export var unit_data:= UnitData.new()

func Hit_Successful(Damage: float, Impact: float, Pen_Rating: float, Direction:= Vector3.ZERO, Position:= Vector3.ZERO):
	var Hit_Position := Position - get_global_transform().origin
	unit_data.take_damage(Damage, Impact, Pen_Rating)
	print("Target Health: ", str(unit_data.health))
	if unit_data.is_dead:
		print("Blehhhh I, ", unit_data.name, ", have perished, my max health of ", unit_data.max_health, " having depleted to ", unit_data.health, " from a shot with damage ", str(Damage), ", impact ", str(Impact), ", and penetration rating ", str(Pen_Rating), ", hit from the direction ", str(Direction), " at the location ", str(Position), ", or, relative to me, ", str(Hit_Position))
		queue_free()
	if Direction != Vector3.ZERO:
		apply_impulse((Direction * (0.1 * Impact)), Hit_Position)
