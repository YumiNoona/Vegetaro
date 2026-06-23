extends Projectile
class_name ProjectileHoming

@export var turn_speed := 2.0

func _process(delta: float) -> void:
	if is_instance_valid(Global.player):
		var direction := global_position.direction_to(Global.player.global_position)
		var angle_diff := velocity.angle_to(direction)
		velocity = velocity.rotated(sign(angle_diff) * turn_speed * delta)
		rotation = velocity.angle()
	position += velocity * delta
