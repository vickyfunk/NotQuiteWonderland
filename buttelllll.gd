extends RigidBody3D

var shoot = false
var is_player_bullet = false

var Damage: float = 0.0
const SPEED = 10

func _ready():
	set_as_top_level(true)
	
func physics_process(delta):
	if shoot:
		apply_impulse(transform.basis.z, -transform.basis.z)


func _on_area_3d_body_entered(body):
	if body.is_in_group("Player") && is_player_bullet:
		return
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
	queue_free()
