extends Node

@export var boss: Boss
@export var minion_scene: PackedScene
@export var minion_damage_multiplier: float = 0.4  # Minions deal 40% of boss damage
@export var minions_per_spawn: int = 3
@export var max_minion_spawns: int = 2
@export var regen_amount: float = 10.0
@export var regen_cooldown: float = 5.0
@export var max_regens: int = 2

var regens_done := 0
var minion_spawns_done := 0
var time_since_last_hit := 0.0
var in_second_phase := false
var health_component: Node = null

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		health_component = boss.get_node("HealthComponent")
		if health_component:
			health_component.on_unit_hit.connect(_on_boss_hit)

func _on_boss_hit(_hitbox):
	time_since_last_hit = 0.0

func _process(delta):
	if Global.game_paused:
		return

	if in_second_phase and regens_done < max_regens:
		time_since_last_hit += delta
		if health_component and time_since_last_hit > regen_cooldown:
			health_component.heal(regen_amount)
			regens_done += 1
			time_since_last_hit = 0.0

func _on_second_phase_started():
	in_second_phase = true
	regens_done = 0
	minion_spawns_done = 0
	# Increase minion damage in second phase
	minion_damage_multiplier = 0.6  # 60% of boss damage in second phase
	call_deferred("_spawn_minions")

func _spawn_minions():
	if minion_spawns_done < max_minion_spawns:
		for i in range(minions_per_spawn):
			var minion = minion_scene.instantiate()
			minion.global_position = boss.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
			minion.add_to_group("enemies")
			
			# Set minion damage based on boss stats
			if minion.has_node("HitboxComponent"):
				var hitbox = minion.get_node("HitboxComponent")
				var minion_damage = boss.stats.damage * minion_damage_multiplier
				hitbox.setup(minion_damage, false, 0, boss)  # damage, critical, knockback, source
			
			
			boss.get_tree().root.call_deferred("add_child", minion)
		minion_spawns_done += 1
