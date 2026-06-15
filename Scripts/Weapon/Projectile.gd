extends Node2D
class_name Projectile

@export var hitbox: HitboxComponent

var velocity: Vector2

func _process(delta: float) -> void:
	position += velocity * delta


func set_projectile(new_velocity: Vector2, damage: float, critical: bool, knockback: float, unit: Node2D) -> void:
	self.velocity = new_velocity
	rotation = new_velocity.angle()
	if hitbox:
		hitbox.setup(damage, critical, knockback, unit)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_hitbox_component_on_hit_hurtbox(_hurtbox: HurtboxComponent) -> void:
	queue_free()
