extends Node2D

enum PhaseType {
	MELEE_RUSH,
	RANGED_ATTACK,
	AREA_DENIAL
}

@export var boss: Boss
@export var phase_switch_interval: float = 10.0  # Switch phases every X seconds
@export var melee_speed_multiplier: float = 1.5
@export var ranged_attack_cooldown: float = 2.0
@export var area_denial_zone_scene: PackedScene

var current_phase: PhaseType = PhaseType.MELEE_RUSH
var phase_timer: float = 0.0
var base_speed: float = 0.0
var shooting_behavior: Node = null
var in_second_phase := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		base_speed = boss.stats.speed
		shooting_behavior = boss.get_node("ShootingBehavior") if boss.has_node("ShootingBehavior") else null
		_switch_phase(PhaseType.MELEE_RUSH)

func _process(delta):
	if Global.game_paused or not boss:
		return
	
	phase_timer += delta
	
	# Switch phases based on health thresholds or time
	if not boss.has_node("HealthComponent"):
		return
	var health_comp = boss.get_node("HealthComponent")
	var health_percent = health_comp.current_health / health_comp.max_health
	
	# Switch phases at health thresholds
	if health_percent > 0.66 and current_phase != PhaseType.MELEE_RUSH:
		_switch_phase(PhaseType.MELEE_RUSH)
	elif health_percent > 0.33 and health_percent <= 0.66 and current_phase != PhaseType.RANGED_ATTACK:
		_switch_phase(PhaseType.RANGED_ATTACK)
	elif health_percent <= 0.33 and current_phase != PhaseType.AREA_DENIAL:
		_switch_phase(PhaseType.AREA_DENIAL)
	
	# Second phase: also switch by time
	if in_second_phase and phase_timer >= phase_switch_interval:
		_cycle_phase()
		phase_timer = 0.0

func _switch_phase(new_phase: PhaseType):
	current_phase = new_phase
	
	match current_phase:
		PhaseType.MELEE_RUSH:
			# Fast movement, high damage
			@warning_ignore("narrowing_conversion")
			boss.stats.speed = int(base_speed * melee_speed_multiplier)
			boss.can_move = true
			if shooting_behavior:
				shooting_behavior.set_process(false)
		
		PhaseType.RANGED_ATTACK:
			# Slower movement, ranged attacks
			@warning_ignore("narrowing_conversion")
			boss.stats.speed = int(base_speed * 0.7)
			boss.can_move = true
			if shooting_behavior:
				shooting_behavior.set_process(true)
		
		PhaseType.AREA_DENIAL:
			# Slow movement, spawn zones
			@warning_ignore("narrowing_conversion")
			boss.stats.speed = int(base_speed * 0.5)
			boss.can_move = true
			if shooting_behavior:
				shooting_behavior.set_process(false)
			_spawn_denial_zones()

func _cycle_phase():
	# Cycle to next phase
	var next_phase = (current_phase + 1) % PhaseType.size()
	_switch_phase(next_phase)

func _spawn_denial_zones():
	if not area_denial_zone_scene:
		return
	
	for i in range(3):
		var zone = area_denial_zone_scene.instantiate()
		boss.get_parent().add_child(zone)
		
		var target_pos: Vector2
		if is_instance_valid(Global.player):
			var angle = (i * TAU / 3) + (get_tree().get_frame() * 0.1)
			var offset = Vector2.RIGHT.rotated(angle) * 200.0
			target_pos = Global.player.global_position + offset
		else:
			target_pos = boss.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		
		zone.global_position = target_pos

func _on_second_phase_started():
	in_second_phase = true
	phase_switch_interval *= 0.7  # Faster phase switching
