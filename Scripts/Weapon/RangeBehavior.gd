extends WeaponBehavior
class_name RangeBehavior

@onready var muzzle: Marker2D = %Muzzle

func execute_attack() -> void:
	weapon.is_attacking = true
	
	create_projectile()
	SoundManager.play_sound(SoundManager.Sound.FIRE)
	
	var tween := create_tween()
	var attack_pos := Vector2(weapon.atk_start_pos.x - weapon.data.stats.recoil, weapon.atk_start_pos.y)
	tween.tween_property(weapon.sprite, "position", attack_pos, weapon.data.stats.recoil_duration)
	tween.tween_property(weapon.sprite, "position", weapon.atk_start_pos, weapon.data.stats.recoil_duration)
	apply_life_steal()
	
	await tween.finished
	weapon.is_attacking = false
	critical = false


func create_projectile() -> void:
	var instance := weapon.data.stats.projectile_scene.instantiate() as Projectile
	get_tree().root.add_child(instance)
	instance.global_position = muzzle.global_position
	
	var velocity := Vector2.RIGHT.rotated(weapon.rotation) * weapon.data.stats.projectile_speed
	instance.set_projectile(velocity, get_damage(), critical, weapon.data.stats.knockback, weapon.get_parent())
