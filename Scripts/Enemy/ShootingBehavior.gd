extends Node2D
class_name ShootingBehavior

@export var enemy: Enemy
@export var fire_pos: Marker2D
@export var cooldown := 3.0
@export var projectile_count := 3
@export_range(-180, 180) var min_angle := -45.0
@export_range(-180, 180) var max_angle := 45.0
@export var projectile_scene: PackedScene
@export var projectile_speed := 1000.0
@export_range(0.1, 10.0, 0.1) var damage_multiplier: float = 1.0  # Direct damage value for projectiles (not a multiplier)

@export var even_spread := true
@export var random_spread := false

var current_cooldown := 0.0

func _ready() -> void:
	current_cooldown = cooldown

func _process(delta: float) -> void:
	if Global.game_paused: return
	
	if enemy == null:
		return

	if current_cooldown > 0:
		current_cooldown -= delta
	else:
		shoot()
		current_cooldown = cooldown

func shoot() -> void:
	if not is_instance_valid(Global.player):
		return

	enemy.can_move = false

	var direction := fire_pos.global_position.direction_to(Global.player.global_position)
	var angles := []

	# 🧠 Spread Angle Logic
	if random_spread:
		for i in range(projectile_count):
			var angle := randf_range(min_angle, max_angle)
			angles.append(angle)

	elif even_spread:
		var spread_range := max_angle - min_angle
		var angle_step := spread_range / float(projectile_count - 1 if projectile_count > 1 else 1)
		for i in range(projectile_count):
			var angle := min_angle + angle_step * i
			angles.append(angle)

	else:
		# Default single center shot
		angles.append(0.0)

	# 🔫 Fire Projectiles
	for angle in angles:
		var projectile := projectile_scene.instantiate() as Projectile
		get_tree().root.add_child(projectile)
		projectile.global_position = fire_pos.global_position

		var rotated_direction := direction.rotated(deg_to_rad(angle))
		var velocity := rotated_direction * projectile_speed
		projectile.rotation = velocity.angle()
		var final_damage = damage_multiplier  # Use the value directly as damage
		projectile.set_projectile(velocity, final_damage, false, 0, enemy)

	await get_tree().create_timer(1).timeout
	enemy.can_move = true
