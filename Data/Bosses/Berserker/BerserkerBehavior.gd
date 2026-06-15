extends Node2D

@export var boss: Boss
@export var max_rage_multiplier: float = 2.5
@export var rage_speed_bonus: float = 100.0
@export var rage_damage_bonus: float = 10.0

var health_component: HealthComponent = null
var base_speed: float = 0.0
var base_damage: float = 0.0
var in_second_phase := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		health_component = boss.get_node("HealthComponent")
		if health_component:
			health_component.on_unit_hit.connect(_on_boss_hit)
		base_speed = boss.stats.speed
		base_damage = boss.stats.damage

func _on_boss_hit(_hitbox):
	if not health_component:
		return
	
	# Calculate rage based on missing health
	var health_percent = health_component.current_health / health_component.max_health
	var missing_health = 1.0 - health_percent
	
	# Apply rage bonuses
	boss.stats.speed = int(base_speed + (rage_speed_bonus * missing_health))
	boss.stats.damage = base_damage + (rage_damage_bonus * missing_health)
	
	# Visual feedback - intensify glow as rage increases
	if boss.has_node("Visuals/Sprite"):
		var sprite = boss.get_node("Visuals/Sprite")
		if sprite:
			var rage_color = Color(1.0, 0.2, 0.2, 1.0).lerp(Color(1.0, 0.0, 0.0, 1.0), missing_health)
			sprite.modulate = rage_color

func _on_second_phase_started():
	in_second_phase = true
	# Second phase: permanent max rage
	boss.stats.speed = int(base_speed + rage_speed_bonus * max_rage_multiplier)
	boss.stats.damage = base_damage + rage_damage_bonus * max_rage_multiplier
