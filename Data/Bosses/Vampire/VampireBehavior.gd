extends Node2D

@export var boss: Boss
@export var life_steal_percent: float = 0.3  # 30% of damage dealt
@export var damage_multiplier: float = 1.0  # Base damage multiplier for the boss
@export var healing_orb_scene: PackedScene = preload("res://Scenes/Items/HealingOrb.tscn")  # Healing orb scene
@export var orb_spawn_chance: float = 0.2  # 20% chance on hit

var health_component: HealthComponent = null
var damage_dealt_tracker: float = 0.0
var in_second_phase := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		health_component = boss.get_node("HealthComponent")
		if health_component:
			# Track when boss deals damage (via hitbox component)
			_setup_damage_tracking()

func _setup_damage_tracking():
	# We'll track damage through the player's health component
	if is_instance_valid(Global.player) and Global.player.has_node("HealthComponent"):
		var player_health = Global.player.get_node("HealthComponent")
		if not player_health.on_unit_hit.is_connected(_on_player_hit):
			player_health.on_unit_hit.connect(_on_player_hit)

func _on_player_hit(hitbox: HitboxComponent):
	if hitbox and hitbox.source == boss:
		# Calculate base damage based on boss stats
		var base_damage = boss.stats.damage * damage_multiplier
		
		# Update hitbox damage to ensure consistency
		hitbox.damage = base_damage
		
		# Calculate heal amount based on actual damage dealt
		var heal_amount = base_damage * life_steal_percent
		
		if health_component:
			health_component.heal(heal_amount)
			
		# Debug output
		print("Vampire boss hit player - Damage: ", base_damage, " | Heal: ", heal_amount)
		
		# Second phase: spawn healing orbs
		if in_second_phase and healing_orb_scene and randf() < orb_spawn_chance:
			_spawn_healing_orb()

func _spawn_healing_orb():
	if not healing_orb_scene:
		push_error("Healing orb scene not set in VampireBehavior!")
		return
	
	var orb = healing_orb_scene.instantiate()
	if not is_instance_valid(boss) or not is_instance_valid(boss.get_parent()):
		push_error("Boss or boss parent is not valid!")
		return
	
	# Add to the same parent as the boss (should be the arena)
	boss.get_parent().add_child(orb)
	
	# Position near the boss but not too close
	var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	if offset.length() < 50:  # Ensure minimum distance from boss
		offset = offset.normalized() * 50
	
	orb.global_position = boss.global_position + offset
	print("Spawned healing orb at position: ", orb.global_position)

func _on_second_phase_started():
	in_second_phase = true
	life_steal_percent *= 1.5  # 45% life steal in second phase
	damage_multiplier *= 1.3  # 30% more damage in second phase
	orb_spawn_chance = 0.4  # Double the orb spawn chance in second phase
	print("Vampire boss entered second phase! Life steal: ", life_steal_percent * 100, "% | Damage multiplier: ", damage_multiplier, " | Orb spawn chance: ", orb_spawn_chance * 100, "%")
