extends Enemy
class_name Boss

signal second_phase_started

var boss_config: BossConfigResource
var second_phase_triggered := false

func setup_boss(config: BossConfigResource):
	boss_config = config
	print("Boss: setup_boss called with config: %s" % boss_config)

func _ready() -> void:
	add_to_group("enemies")  # ✅ Needed for clear_enemies()
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
			emit_signal("second_phase_started")
