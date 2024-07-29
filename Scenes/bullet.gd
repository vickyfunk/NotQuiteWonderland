extends RigidBody3D

var shoot: bool = false
var Damage: int = 0
var Speed: float = 10.0
var is_player_bullet: bool = false
#@onready var tracer_emitter: GPUParticles3D = get_node("TracerParticleEmitter")
#var time_since_particle: float = 0.0

func ready():
	set_as_top_level(true)
	
func _physics_process(delta):
	#time_since_particle += delta
	#if time_since_particle > 0.1:
		#tracer_emitter.emit_particle(Transform3D(), Vector3(), Color(Color.RED), Color(), 8)
		#print("emitting particle")
		#time_since_particle = 0.0
	if shoot:
		apply_impulse(transform.basis.z, -transform.basis.z * Speed)

func _on_body_entered(body):
	if body.is_in_group("Player") && is_player_bullet:
		return
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
		print("Hit Successful")
	
	queue_free()

func _on_timer_timeout():
	queue_free()

func _on_tree_exited():
	pass # Replace with function body.
