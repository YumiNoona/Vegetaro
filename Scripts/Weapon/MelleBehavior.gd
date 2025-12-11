extends WeaponBehavior
class_name MelleBehavior


@export var hitbox : HitboxComponent

func execute_attack() -> void:
	weapon.is_attacking = true

	var tween := create_tween()

	var recoil_pos := Vector2(weapon.atk_start_pos.x - weapon.data.stats.recoil, weapon.atk_start_pos.y)
	tween.tween_property(weapon.sprite, "position", recoil_pos, weapon.data.stats.recoil_duration)

	hitbox.enable()
	hitbox.setup(get_damage(), critical, weapon.data.stats.knockback, weapon.get_parent())
	
	var attack_pos := Vector2(weapon.atk_start_pos.x + weapon.data.stats.max_range,weapon.atk_start_pos.y)
	tween.tween_property(weapon.sprite, "position", attack_pos, weapon.data.stats.attack_duration)


	apply_life_steal()
	
	tween.tween_property(weapon.sprite, "position",weapon.atk_start_pos, weapon.data.stats.back_duration)

	tween.finished.connect(func():
		hitbox.disable()
		weapon.is_attacking = false
		critical = false
		)
