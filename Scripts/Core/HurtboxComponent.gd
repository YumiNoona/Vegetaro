extends Area2D
class_name HurtboxComponent

signal on_damaged(hitbox: HitboxComponent)



func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		on_damaged.emit(area)
		# If you have a reference to HealthComponent:
		if has_node("HealthComponent"):
			get_node("HealthComponent").take_damage(area.damage, area)
