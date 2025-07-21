extends Area2D
class_name HitboxComponent

signal on_hit_hurtbox(hurtbox: HurtboxComponent)


var damage := 1.0
var critical := false
var knockback_power := 0.0
var source : Node2D

func enable() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func setup(damage: float, critical: bool, knockback: float, source: Node2D) -> void:
	self.damage         = damage
	self.critical       = critical
	self.source         = source
	knockback_power     = knockback   # no collision here

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		on_hit_hurtbox.emit(area)
	SoundManager.play_sound(SoundManager.Sound.ENEMY_HIT)
