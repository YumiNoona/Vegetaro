extends Enemy
class_name Boss

signal second_phase_started
signal boss_defeated

var boss_config: BossConfigResource
var second_phase_triggered := false
var second_phase_timer := 0.0


func setup_boss(config: BossConfigResource, wave_index: int = 5):
	boss_config = config
	# Reduce damage for early bosses to make them more fair
	if wave_index <= 10:
		# Wave 5-10: Reduce damage by 60%
		stats.damage *= 0.4
	elif wave_index <= 20:
		# Wave 15-20: Reduce damage by 40%
		stats.damage *= 0.6
	elif wave_index <= 30:
		# Wave 25-30: Reduce damage by 20%
		stats.damage *= 0.8
	# Waves 35+ use full damage

func _ready() -> void:
	add_to_group("enemies")
	connect_second_phase()
	$HealthComponent.on_unit_died.connect(_on_boss_died)

func connect_second_phase():
	if $HealthComponent:
		$HealthComponent.on_unit_hit.connect(_on_unit_hit)

func _on_unit_hit(_hitbox):
	if boss_config and boss_config.has_second_phase and not second_phase_triggered:
		var threshold = boss_config.second_phase_threshold * $HealthComponent.max_health
		if $HealthComponent.current_health <= threshold:
			second_phase_triggered = true

			if boss_config.camera_shake_on_second_phase:
				var camera = get_viewport().get_camera_2d()
				if camera and camera.has_method("shake"):
					camera.shake(boss_config.camera_shake_strength)

			# Update max health to second phase HP and set current to max
			$HealthComponent.max_health = boss_config.second_phase_hp
			$HealthComponent.current_health = boss_config.second_phase_hp
			$HealthComponent.on_health_changed.emit($HealthComponent.current_health, $HealthComponent.max_health)

			# Modify stats for second phase
			if boss_config.second_phase_speed > 0:
				stats.speed = int(boss_config.second_phase_speed)
			if boss_config.second_phase_attack > 0:
				# Get wave index from spawner if available
				var current_wave = 5  # Default
				var arena = get_tree().get_first_node_in_group("arena")
				if arena and arena.has_node("Spawner"):
					var spawner = arena.get_node("Spawner")
					if spawner:
						current_wave = spawner.wave_index
				
				var second_phase_damage = boss_config.second_phase_attack
				# Reduce second phase damage for early bosses
				if current_wave <= 10:
					second_phase_damage *= 0.4
				elif current_wave <= 20:
					second_phase_damage *= 0.6
				elif current_wave <= 30:
					second_phase_damage *= 0.8
				
				stats.damage = second_phase_damage

			_enter_second_phase_visuals()
			emit_signal("second_phase_started")

func _enter_second_phase_visuals():
	# Scale up only the visuals node
	if has_node("Visuals"):
		var visuals_node = get_node("Visuals")
		var scale_value = boss_config.second_phase_scale if boss_config.second_phase_scale > 0 else 1.5
		visuals_node.scale = Vector2(scale_value, scale_value) # Set directly, not just tween
		var tween = create_tween()
		tween.tween_property(visuals_node, "scale", Vector2(scale_value, scale_value), 0.5)

	# Apply second phase material and set shader params
	if sprite and boss_config.second_phase_material:
		sprite.material = boss_config.second_phase_material.duplicate()
		second_phase_timer = 0.0
		var mat = sprite.material
		if mat is ShaderMaterial:
			mat.set_shader_parameter("pulse_speed", boss_config.second_phase_pulse_speed)
			mat.set_shader_parameter("glow_color", boss_config.second_phase_glow_color)
			mat.set_shader_parameter("time", 0.0)

func _on_boss_died() -> void:
	emit_signal("boss_defeated")

func _process(delta: float) -> void:
	# Debug movement
	if Global.game_paused: return
	if not can_move: return
	if not can_move_toward_player(): return

	var move_vec = (get_move_direction() + knockback_dir * knockback_power) * stats.speed * delta
	position += move_vec
	update_rotation()

	# Shader update
	if sprite and sprite.material and sprite.material is ShaderMaterial:
		second_phase_timer += delta
		sprite.material.set_shader_parameter("time", second_phase_timer)
