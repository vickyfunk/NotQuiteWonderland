extends Node3D

@export var speed = 40.0
var is_coll = false

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D



# Called when the node enters the scene tree for the first time.
func ready():
	pass

# Called every physics frame which is by default 60 times per second. 'delta' is the elapsed time since previous physics frame.
# Best practice is to scale movement by delta anyway as to allow us to adjust the framerate later in development.
func _physics_process(_delta):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print("In the %s time since last fired, moved %s" % [delta, speed * delta])
	position += transform.basis * Vector3(0, 0, speed) * delta
	if ray.is_colliding():
		if (!is_coll):
			print("Visible bullet ray is colliding")
		else:
			print("Collision bullet ray is colliding")
