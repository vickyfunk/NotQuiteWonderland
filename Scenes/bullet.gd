extends RigidBody3D

#todo: probably condense all of these down into a "projectile data" packet
var shoot: bool = false
var Damage: float = 0.0
var Impact: float = 0.0
var Pen_Rating: float = 0.0
var Speed: float = 10.0
var is_player_bullet: bool = false
#@onready var tracer_trail: MeshInstance3D = get_node("TracerTrail")
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
	look_at(transform.origin + linear_velocity, Vector3.UP)

func _on_body_entered(body):
	if body.is_in_group("Player") && is_player_bullet:
		return
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage, Impact, Pen_Rating, get_global_transform().basis * Vector3.FORWARD, get_global_transform().origin)
		print("Hit Successful")
	
	queue_free()

func _on_timer_timeout():
	queue_free()

func _on_tree_exited():
	pass # Replace with function body.
