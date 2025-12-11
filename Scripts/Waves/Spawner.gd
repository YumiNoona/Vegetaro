extends Node2D
class_name Spawner


signal on_wave_completed

# Reference to the current boss (if any)
var current_boss: Node = null

@export var enemy_collection: Array[UnitStats]
@export var waves_data: Array[WaveData]
@export var spawn_area_size := Vector2(1000,500) #Clamped Form Player position.x = clamp(position.x,-1000, 1000)

# Boss scenes for dynamic boss waves
@export var boss_minions_scene: PackedScene = preload("res://Data/Bosses/Minions/BossMinions.tscn")
@export var boss_minions_config: Resource = preload("res://Data/Bosses/Minions/BossMinions.tres")
@export var boss_teleport_scene: PackedScene = preload("res://Data/Bosses/Teleport/BossTeleport.tscn")
@export var boss_teleport_config: Resource = preload("res://Data/Bosses/Teleport/BossTeleport.tres")
@export var boss_shield_scene: PackedScene = preload("res://Data/Bosses/Shield/BossSheild.tscn")
@export var boss_shield_config: Resource = preload("res://Data/Bosses/Shield/BossShield.tres")
@export var boss_berserker_scene: PackedScene = preload("res://Data/Bosses/Berserker/BossBerserker.tscn")
@export var boss_berserker_config: Resource = preload("res://Data/Bosses/Berserker/BossBerserker.tres")
@export var boss_tank_scene: PackedScene = preload("res://Data/Bosses/Tank/BossTank.tscn")
@export var boss_tank_config: Resource = preload("res://Data/Bosses/Tank/BossTank.tres")
@export var boss_vampire_scene: PackedScene = preload("res://Data/Bosses/Vampire/BossVampire.tscn")
@export var boss_vampire_config: Resource = preload("res://Data/Bosses/Vampire/BossVampire.tres")
@export var boss_bomber_scene: PackedScene = preload("res://Data/Bosses/Bomber/BossBomber.tscn")
@export var boss_bomber_config: Resource = preload("res://Data/Bosses/Bomber/BossBomber.tres")
@export var boss_phase_scene: PackedScene = preload("res://Data/Bosses/Phase/BossPhase.tscn")
@export var boss_phase_config: Resource = preload("res://Data/Bosses/Phase/BossPhase.tres")

# Enemy scenes for dynamic wave generation
@export var enemy_chaser_slow_scene: PackedScene = preload("res://Scenes/Enemy/EnemyChaserSlow.tscn")
@export var enemy_chaser_mid_scene: PackedScene = preload("res://Scenes/Enemy/EnemyChaserMid.tscn")
@export var enemy_chaser_fast_scene: PackedScene = preload("res://Scenes/Enemy/EnemyChaserFast.tscn")
@export var enemy_charger_scene: PackedScene = preload("res://Scenes/Enemy/EnemyCharger.tscn")
@export var enemy_shooter_scene: PackedScene = preload("res://Scenes/Enemy/EnemyShooter.tscn")

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

var wave_index := 15  # Start at wave 5 (first boss) for testing
var current_wave_data : WaveData
var spawned_enemies : Array[Enemy] = []
var use_dynamic_waves := false  # Set to true after wave 25 for infinite mode

func find_wave_data() -> WaveData:
	# First, try to find predefined wave data
	for wave in waves_data:
		if wave and wave.is_valid_index(wave_index):
			return wave
	
	# If no predefined wave found, generate dynamically (infinite mode)
	return generate_wave_data()

func get_boss_scene_and_config(wave: int) -> Dictionary:
	var boss_scenes = [
		{ "scene": boss_minions_scene, "config": boss_minions_config, "name": "The Swarm Lord" },
		{ "scene": boss_teleport_scene, "config": boss_teleport_config, "name": "The Shadow" },
		{ "scene": boss_shield_scene, "config": boss_shield_config, "name": "The Guardian" },
		{ "scene": boss_berserker_scene, "config": boss_berserker_config, "name": "The Berserker" },
		{ "scene": boss_tank_scene, "config": boss_tank_config, "name": "The Fortress" },
		{ "scene": boss_vampire_scene, "config": boss_vampire_config, "name": "The Bloodsucker" },
		{ "scene": boss_bomber_scene, "config": boss_bomber_config, "name": "The Demolisher" },
		{ "scene": boss_phase_scene, "config": boss_phase_config, "name": "The Shapeshifter" }
	]
	
	# Before wave 40, use fixed boss order
	if wave < 40:
		@warning_ignore("integer_division")
		var boss_index = (int(floor(wave / 5.0)) - 1) % boss_scenes.size()
		return boss_scenes[boss_index]
	else:
		# After wave 40, select a random boss
		var random_index = randi() % boss_scenes.size()
		return boss_scenes[random_index]

func calculate_boss_scale(wave: int) -> float:
	# Base scale increases every 10 waves after 40
	var scale_increase = max(0, (wave - 40) / 10.0) * 0.2
	# Add some random variation
	scale_increase += randf_range(-0.1, 0.1)
	return 1.0 + scale_increase

func calculate_boss_stats_scale(wave: int) -> float:
	# Stats scale faster than size
	var boss_scale = 1.0 + (wave - 40) * 0.1  # 10% increase per wave after 40
	# Add some random variation
	boss_scale *= randf_range(0.9, 1.1)
	return max(1.0, boss_scale)

func generate_wave_data() -> WaveData:
	# Create a new WaveData resource dynamically
	var wave_data = WaveData.new()
	
	# Check if this is a boss wave (every 5th wave)
	var is_boss = (wave_index % 5 == 0)
	
	if is_boss:
		# Boss wave configuration
		wave_data.is_boss_wave = true
		wave_data.wave_time = 60.0  # Boss waves last longer
		
		# Get boss scene and config
		var boss_data = get_boss_scene_and_config(wave_index)
		wave_data.boss_scene = boss_data.scene
		wave_data.boss_config = boss_data.config.duplicate()  # Create a copy to modify
		
		# Scale boss stats for waves after 40
		if wave_index >= 40:
			var scale_factor = calculate_boss_stats_scale(wave_index)
			var size_scale = calculate_boss_scale(wave_index)
			
			# Apply scaling to boss config
			if wave_data.boss_config.has_method("scale_stats"):
				wave_data.boss_config.scale_stats(scale_factor, size_scale)
			else:
				# Fallback scaling for configs without scale_stats method
				wave_data.boss_config.second_phase_hp *= scale_factor
				wave_data.boss_config.second_phase_speed *= sqrt(scale_factor)
				wave_data.boss_config.second_phase_attack *= scale_factor
				wave_data.boss_config.second_phase_scale *= size_scale
		
		# Boss waves can still have some regular enemies
		wave_data.spawn_type = WaveData.SpawnType.RANDOM
		wave_data.min_spawn_time = 2.0
		wave_data.max_spawn_time = 4.0
		# Clear any existing units
		wave_data.units.clear()
	else:
		# Regular wave configuration - progressive difficulty
		wave_data.is_boss_wave = false
		wave_data.spawn_type = WaveData.SpawnType.RANDOM
		
		# Calculate difficulty tier (every 10 waves = new tier)
		@warning_ignore("integer_division")
		var tier = int((wave_index - 1) / 10) + 1
		
		# Wave time scales with difficulty (slightly longer for higher waves)
		wave_data.wave_time = 15.0 + (tier * 2.0)
		wave_data.wave_time = min(wave_data.wave_time, 45.0)  # Cap at 45 seconds
		
		# Spawn rate gets faster as waves progress
		var base_min_spawn = 0.8
		var base_max_spawn = 1.5
		var spawn_reduction = tier * 0.1
		wave_data.min_spawn_time = max(0.1, base_min_spawn - spawn_reduction)
		wave_data.max_spawn_time = max(0.3, base_max_spawn - spawn_reduction)
		
		# Generate enemy units based on wave difficulty and add them to the wave data
		var enemy_units = generate_enemy_units_for_wave(tier)
		for unit in enemy_units:
			wave_data.units.append(unit)
	
	return wave_data

func generate_enemy_units_for_wave(tier: int) -> Array[WaveUnitData]:
	print("[DEBUG] Generating enemy units for tier: ", tier)  # Debug print
	var units: Array[WaveUnitData] = []
	
	# Tier 1 (Waves 1-10): Mostly slow chasers, some mid
	if tier == 1:
		var slow_unit = WaveUnitData.new()
		slow_unit.unit_scene = enemy_chaser_slow_scene
		slow_unit.weight = 8
		units.append(slow_unit)
		
		var mid_unit = WaveUnitData.new()
		mid_unit.unit_scene = enemy_chaser_mid_scene
		mid_unit.weight = 2
		units.append(mid_unit)
	
	# Tier 2 (Waves 11-20): Mix of slow, mid, and fast
	elif tier == 2:
		var slow_unit = WaveUnitData.new()
		slow_unit.unit_scene = enemy_chaser_slow_scene
		slow_unit.weight = 5
		units.append(slow_unit)
		
		var mid_unit = WaveUnitData.new()
		mid_unit.unit_scene = enemy_chaser_mid_scene
		mid_unit.weight = 4
		units.append(mid_unit)
		
		var fast_unit = WaveUnitData.new()
		fast_unit.unit_scene = enemy_chaser_fast_scene
		fast_unit.weight = 1
		units.append(fast_unit)
	
	# Tier 3 (Waves 21-30): Add chargers, more variety
	elif tier == 3:
		var slow_unit = WaveUnitData.new()
		slow_unit.unit_scene = enemy_chaser_slow_scene
		slow_unit.weight = 4
		units.append(slow_unit)
		
		var mid_unit = WaveUnitData.new()
		mid_unit.unit_scene = enemy_chaser_mid_scene
		mid_unit.weight = 4
		units.append(mid_unit)
		
		var fast_unit = WaveUnitData.new()
		fast_unit.unit_scene = enemy_chaser_fast_scene
		fast_unit.weight = 2
		units.append(fast_unit)
		
		var charger_unit = WaveUnitData.new()
		charger_unit.unit_scene = enemy_charger_scene
		charger_unit.weight = 2
		units.append(charger_unit)
	
	# Tier 4+ (Waves 31+): All enemy types, shooters appear
	else:
		var slow_unit = WaveUnitData.new()
		slow_unit.unit_scene = enemy_chaser_slow_scene
		slow_unit.weight = 3
		units.append(slow_unit)
		
		var mid_unit = WaveUnitData.new()
		mid_unit.unit_scene = enemy_chaser_mid_scene
		mid_unit.weight = 3
		units.append(mid_unit)
		
		var fast_unit = WaveUnitData.new()
		fast_unit.unit_scene = enemy_chaser_fast_scene
		fast_unit.weight = 2
		units.append(fast_unit)
		
		var charger_unit = WaveUnitData.new()
		charger_unit.unit_scene = enemy_charger_scene
		charger_unit.weight = 2
		units.append(charger_unit)
		
		# Shooters appear from tier 4 onwards
		if tier >= 4:
			var shooter_unit = WaveUnitData.new()
			shooter_unit.unit_scene = enemy_shooter_scene
			shooter_unit.weight = 2
			units.append(shooter_unit)
	
	return units

func start_wave() -> void:
	if not is_instance_valid(Global.player):
		push_error("Cannot start wave: Player not valid")
		return

	current_wave_data = find_wave_data()
	if not current_wave_data:
		printerr("No Valid Wave.")
		spawn_timer.stop()
		wave_timer.stop()
		return

	wave_timer.wait_time = current_wave_data.wave_time
	wave_timer.start()

	if current_wave_data.is_boss_wave and current_wave_data.boss_scene:
		spawn_boss()
		# Boss waves only spawn the boss and its minions, no regular enemies
	else:
		set_spawn_timer()  # Only set spawn timer for non-boss waves

	
func set_spawn_timer() -> void:
	match current_wave_data.spawn_type:
		WaveData.SpawnType.FIXED:
			spawn_timer.wait_time = current_wave_data.fixed_spawn_time
		WaveData.SpawnType.RANDOM:
			var min_t := current_wave_data.min_spawn_time
			var max_t := current_wave_data.max_spawn_time
			spawn_timer.wait_time = randf_range(min_t, max_t)
			
	if spawn_timer.is_stopped():
		spawn_timer.start()
		
		
func spawn_enemy() -> void:
	var enemy_scene := current_wave_data.get_random_unit_scene() as PackedScene
	if enemy_scene:
		var spawn_pos := get_random_spawn_position() 
		var spawn_anim := Global.ENEMY_SPAWN_EFFECT_SCENE.instantiate()
		get_parent().add_child(spawn_anim)
		spawn_anim.global_position = spawn_pos
		await  spawn_anim.animated_sprite.animation_finished
		spawn_anim.queue_free()
		
		
		var enemy_instance := enemy_scene.instantiate() as Enemy
		enemy_instance.global_position  = spawn_pos
		get_parent().add_child(enemy_instance)
		spawned_enemies.append(enemy_instance)
		
	if not is_instance_valid(Global.player):
		spawn_timer.stop()
		return
	
	set_spawn_timer()


func update_enemies_new_wave() -> void:
	for stat: UnitStats in enemy_collection:
		stat.health += stat.health_increase_per_wave
		stat.damage += stat.damage_increase_per_wave

func get_wave_text() -> String:
	return "Wave %s" % wave_index


func clear_enemies() -> void:
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("destroy_enemy"):
				enemy.destroy_enemy()
			else:
				enemy.queue_free()
	spawned_enemies.clear()



func get_wave_timer_text() -> String:
	return str(max(0, int(wave_timer.time_left)))



func get_random_spawn_position() -> Vector2:
	var random_x:= randf_range(-spawn_area_size.x, spawn_area_size.x)
	var random_y:= randf_range(-spawn_area_size.y, spawn_area_size.y)
	return Vector2(random_x, random_y)
	

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(Global.player):
		spawn_timer.stop()
		return

	if not current_wave_data or wave_timer.is_stopped():
		spawn_timer.stop()
		return

	spawn_enemy()

		
	if not is_instance_valid(Global.player):
		spawn_timer.stop()
		return
		
	spawn_enemy()


func show_game_over():
	var panel = Global.GAME_OVER_SCENE.instantiate()
	get_tree().root.add_child(panel)
	get_tree().paused = true
	panel.process_mode = Node.PROCESS_MODE_ALWAYS # So UI still works when paused




func _on_wave_timer_timeout() -> void:
	if not is_instance_valid(Global.player):
		# Player is dead, show game over
		spawn_timer.stop()
		wave_timer.stop()
		# Signal to Arena to show game over
		Global.on_player_died.emit()
		return
		
	Global.game_paused = true
	Global.get_harvesting_coins()
	on_wave_completed.emit()
	spawn_timer.stop()
	clear_enemies()
	update_enemies_new_wave()


func get_boss_name(wave: int) -> String:
	# For waves after 40, we need to get the random boss name
	if wave >= 40 and wave % 5 == 0:  # Only for boss waves
		var boss_data = get_boss_scene_and_config(wave)
		var name_str = boss_data.name
		var scale_factor = calculate_boss_stats_scale(wave)
		
		# Add elite indicator if significantly scaled
		if scale_factor > 1.5:
			var elite_level = min(5, int((scale_factor - 1.0) / 0.3))
			var elite_prefix = "★".repeat(elite_level) + " "
			name_str = elite_prefix + name_str
		
		print("[DEBUG] Getting random boss name for wave ", wave, ": ", name_str, " (Scale: ", scale_factor, "x)")
		return name_str
	
	# For waves before 40, use the fixed mapping
	var name_result: String
	match wave:
		5: name_result = "The Swarm Lord"    # BossMinions
		10: name_result = "The Shadow"       # BossTeleport
		15: name_result = "The Guardian"     # BossShield
		20: name_result = "The Berserker"    # BossBerserker
		25: name_result = "The Fortress"     # BossTank
		30: name_result = "The Bloodsucker"  # BossVampire
		35: name_result = "The Demolisher"   # BossBomber
		40: name_result = "The Shapeshifter" # BossPhase
		_: name_result = "Boss Wave " + str(wave)  # Fallback
	
	print("[DEBUG] Getting boss name for wave ", wave, ": ", name_result)
	return name_result

func spawn_boss() -> void:
	print("[DEBUG] spawn_boss() called for wave ", wave_index)
	var _spawn_pos := get_random_spawn_position()
	
	# Create spawn effect
	var spawn_anim = Global.ENEMY_SPAWN_EFFECT_SCENE.instantiate()
	spawn_anim.global_position = _spawn_pos
	get_parent().add_child(spawn_anim)
	
	var boss = current_wave_data.boss_scene.instantiate()
	if boss and boss.has_method("setup_boss"):
		print("[DEBUG] Setting up boss for wave ", wave_index)
		
		# Calculate scale for this boss
		var scale_factor = 1.0
		if wave_index >= 40:
			scale_factor = calculate_boss_scale(wave_index)
			
		# Apply scale to boss
		if boss.has_method("set_scale"):
			boss.scale *= scale_factor
		
		# Setup boss with config
		boss.setup_boss(current_wave_data.boss_config, wave_index)
		boss.global_position = _spawn_pos
		get_parent().add_child(boss)
		spawned_enemies.append(boss)
		current_boss = boss  # Store reference to current boss
		
		# Show boss name with appropriate scaling
		show_boss_name(boss)
		
		# Connect the boss_defeated signal if it exists
		if boss.has_signal("boss_defeated"):
			print("[DEBUG] Connecting to boss_defeated signal")
			if not boss.boss_defeated.is_connected(_on_boss_defeated):
				boss.boss_defeated.connect(_on_boss_defeated)
		else:
			print("[WARNING] Boss does not have boss_defeated signal")
		
		print("[DEBUG] Spawned boss: ", boss.name, " at position: ", boss.global_position, " with scale: ", scale_factor)
	else:
		print("[ERROR] Failed to create boss instance or boss is missing setup_boss method")

func _on_boss_defeated() -> void:
	print("Boss defeated, ending wave...")
	wave_timer.stop()
	end_wave()

func end_wave() -> void:
	Global.game_paused = true
	Global.get_harvesting_coins()
	on_wave_completed.emit()
	spawn_timer.stop()
	clear_enemies()
	update_enemies_new_wave()

func show_boss_name(boss_instance):
	if not boss_instance:
		print("[ERROR] show_boss_name: boss_instance is null")
		return
		
	var boss_name = get_boss_name(wave_index)
	print("[DEBUG] Showing boss name for wave ", wave_index, ": ", boss_name)
	
	var boss_name_label_scene = preload("res://Scenes/UI/BossNameLabel.tscn")
	if not boss_name_label_scene:
		print("[ERROR] Failed to load BossNameLabel scene")
		return
		
	var boss_name_label = boss_name_label_scene.instantiate()
	if not boss_name_label:
		print("[ERROR] Failed to instantiate BossNameLabel")
		return
		
	boss_instance.add_child(boss_name_label)
	print("[DEBUG] Added BossNameLabel as child to boss_instance")
	
	if boss_name_label.has_method("setup"):
		boss_name_label.setup(boss_name)
		print("[DEBUG] Called setup on BossNameLabel with name: ", boss_name)
	else:
		print("[ERROR] BossNameLabel does not have setup method")
