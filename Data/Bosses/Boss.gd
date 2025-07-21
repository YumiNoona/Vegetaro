extends Enemy
class_name Boss

signal second_phase_started

var boss_config: BossConfigResource
var second_phase_triggered := false
var second_phase_timer := 0.0


func setup_boss(config: BossConfigResource):
	boss_config = config
	print("Boss: setup_boss called with config: %s" % boss_config)

func _ready() -> void:
	add_to_group("enemies")
	print("Boss: _ready called")
	connect_second_phase()

func connect_second_phase():
	if $HealthComponent:
		print("Boss: Connecting on_unit_hit signal")
		$HealthComponent.on_unit_hit.connect(_on_unit_hit)
	else:
		print("Boss: No HealthComponent found!")

func _on_unit_hit():
	print("Boss: _on_unit_hit called. Current HP: %s" % $HealthComponent.current_health)
	if boss_config and boss_config.has_second_phase and not second_phase_triggered:
		var threshold = boss_config.second_phase_threshold * $HealthComponent.max_health
		if $HealthComponent.current_health <= threshold:
			second_phase_triggered = true
			print("Boss: Second phase triggered!")

			if boss_config.camera_shake_on_second_phase:
				var camera = get_viewport().get_camera_2d()
				if camera and camera.has_method("shake"):
					camera.shake(boss_config.camera_shake_strength)

			$HealthComponent.current_health = boss_config.second_phase_hp
			$HealthComponent.on_health_changed.emit($HealthComponent.current_health, $HealthComponent.max_health)

			# Modify stats for second phase
			if boss_config.second_phase_speed > 0:
				stats.speed = boss_config.second_phase_speed
			if boss_config.second_phase_attack > 0:
				stats.damage = boss_config.second_phase_attack
				print("Boss: Damage set to ", stats.damage)

			_enter_second_phase_visuals()
			emit_signal("second_phase_started")

func _enter_second_phase_visuals():
	# Scale up only the visuals node
	if has_node("Visuals"):
		var visuals = get_node("Visuals")
		var scale = boss_config.second_phase_scale if boss_config.second_phase_scale > 0 else 1.5
		visuals.scale = Vector2(scale, scale) # Set directly, not just tween
		var tween = create_tween()
		tween.tween_property(visuals, "scale", Vector2(scale, scale), 0.5)
		print("Scaling visuals to: ", scale)

	# Apply second phase material and set shader params
	if sprite and boss_config.second_phase_material:
		sprite.material = boss_config.second_phase_material.duplicate()
		second_phase_timer = 0.0
		var mat = sprite.material
		if mat is ShaderMaterial:
			mat.set_shader_parameter("pulse_speed", boss_config.second_phase_pulse_speed)
			mat.set_shader_parameter("glow_color", boss_config.second_phase_glow_color)
			mat.set_shader_parameter("time", 0.0)
			print("Boss: Shader params set (pulse_speed: %s, glow_color: %s)" % [boss_config.second_phase_pulse_speed, boss_config.second_phase_glow_color])

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
