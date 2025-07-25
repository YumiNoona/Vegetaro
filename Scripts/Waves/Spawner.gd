extends Node2D
class_name Spawner


signal on_wave_completed

@export var enemy_collection: Array[UnitStats]
@export var waves_data: Array[WaveData]
@export var spawn_area_size := Vector2(1000,500) #Clamped Form Player position.x = clamp(position.x,-1000, 1000)


@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer



var wave_index := 1
var current_wave_data : WaveData
var spawned_enemies : Array[Enemy] = []

func find_wave_data() -> WaveData:
	for wave in waves_data:
		if wave and wave.is_valid_index(wave_index):
			return wave
	return null

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
	else:
		set_spawn_timer()

	
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
		print("Spawner: Player is not valid, stopping spawn.")
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
		print("Spawner: Player is not valid, stopping spawn.")
		spawn_timer.stop()
		return

	if not current_wave_data or wave_timer.is_stopped():
		spawn_timer.stop()
		return

	spawn_enemy()

		
	if not is_instance_valid(Global.player):
		print("Spawner: Player is not valid, stopping spawn.")
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
		show_game_over()
		return
		
	Global.game_paused = true
	Global.get_harvesting_coins()
	on_wave_completed.emit()
	spawn_timer.stop()
	clear_enemies()
	update_enemies_new_wave()


func spawn_boss() -> void:
	var spawn_pos := get_random_spawn_position()
	var spawn_anim := Global.ENEMY_SPAWN_EFFECT_SCENE.instantiate()
	get_parent().add_child(spawn_anim)
	spawn_anim.global_position = spawn_pos
	await spawn_anim.animated_sprite.animation_finished
	spawn_anim.queue_free()

	var boss_instance := current_wave_data.boss_scene.instantiate()
	boss_instance.global_position = spawn_pos
	if boss_instance.has_method("setup_boss"):
		boss_instance.setup_boss(current_wave_data.boss_config)
	get_parent().add_child(boss_instance)
	spawned_enemies.append(boss_instance)
