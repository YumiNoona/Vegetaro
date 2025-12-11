extends Node2D

@export var boss: Boss
@export var zone_scene: PackedScene  # Area2D with collision and visual
@export var zone_damage: float = 3.0
@export var zone_duration: float = 5.0
@export var zone_cooldown: float = 4.0
@export var zone_radius: float = 200.0
@export var zones_per_spawn: int = 1
@export var second_phase_zones_per_spawn: int = 2

var zones: Array[Area2D] = []
var cooldown_timer: float = 0.0
var in_second_phase := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		cooldown_timer = zone_cooldown

func _process(delta):
	if Global.game_paused or not boss:
		return
	
	# Clean up expired zones
	zones = zones.filter(func(zone): return is_instance_valid(zone))
	
	# Spawn zones on cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
	else:
		_spawn_zones()
		cooldown_timer = zone_cooldown

func _spawn_zones():
	if not boss or not zone_scene:
		return
	
	var num_zones = zones_per_spawn if not in_second_phase else second_phase_zones_per_spawn
	
	for i in range(num_zones):
		var zone = zone_scene.instantiate()
		boss.get_parent().add_child(zone)
		
		# Position zone near player or boss
		var target_pos: Vector2
		if is_instance_valid(Global.player):
			target_pos = Global.player.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		else:
			target_pos = boss.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		
		zone.global_position = target_pos
		
		# Setup zone damage
		if zone.has_node("Area2D"):
			var area = zone.get_node("Area2D")
			area.body_entered.connect(_on_zone_body_entered.bind(zone))
		
		zones.append(zone)
		
		# Auto-remove zone after duration
		await get_tree().create_timer(zone_duration).timeout
		if is_instance_valid(zone):
			zone.queue_free()
			zones.erase(zone)

func _on_zone_body_entered(body, _zone):
	if body == Global.player and body.has_node("HealthComponent"):
		var health_comp = body.get_node("HealthComponent")
		health_comp.take_damage(zone_damage, null)

func _on_second_phase_started():
	in_second_phase = true
	zone_cooldown *= 0.7  # Faster zone spawning
