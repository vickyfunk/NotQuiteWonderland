extends Node3D

var mouse_mov_x
var mouse_mov_y
var sway_threshold = 5
var sway_lerp = 5

@export var sway_up : Vector3
@export var sway_down : Vector3
@export var sway_left : Vector3
@export var sway_right : Vector3
@export var sway_default : Vector3
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov_x = -event.relative.x
		mouse_mov_y = -event.relative.y
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var sway_final : Vector3 = sway_default
	if mouse_mov_x != null:
		if mouse_mov_x > sway_threshold:
			sway_final += sway_left
		elif mouse_mov_x < -sway_threshold:
			sway_final += sway_right
	if mouse_mov_y != null:
		if mouse_mov_y > sway_threshold:
			sway_final += sway_up
		elif mouse_mov_y < -sway_threshold:
			sway_final += sway_down
	
	rotation = rotation.lerp(sway_final, sway_lerp * delta)
