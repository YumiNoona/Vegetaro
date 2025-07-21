extends Area2D
class_name HurtboxComponent

signal on_damaged(hitbox: HitboxComponent)



func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		on_damaged.emit(area)
