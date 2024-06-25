extends RigidBody3D

var Damage: int = 0
var is_player_bullet: bool = false

func _on_body_entered(body):
	if body.is_in_group("Player") && is_player_bullet:
		return
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
		print("Hit Successful")
		queue_free()
	
	queue_free()

func _on_timer_timeout():
	queue_free()

func _on_tree_exited():
	pass # Replace with function body.
