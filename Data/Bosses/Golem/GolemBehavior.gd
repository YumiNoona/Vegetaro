extends Node2D

@export var boss: Boss
@export var shower_scene: PackedScene
@export var golem_scene: PackedScene
@export var shower_count := 5
@export var shower_angle := 30.0
@export var shower_cooldown := 3.0
@export var projectile_speed := 800.0
@export var phase2_shower_count := 7
@export var phase2_cooldown := 2.0

var cooldown_timer := 0.0
var in_second_phase := false
var cycle_counter := 0

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		cooldown_timer = shower_cooldown

func _process(delta):
	if Global.game_paused or not boss:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		if in_second_phase:
			_fire_shower(phase2_shower_count)
			if cycle_counter % 2 == 0:
				_fire_golem_shot()
			cycle_counter += 1
			cooldown_timer = phase2_cooldown
		else:
			_fire_shower(shower_count)
			cooldown_timer = shower_cooldown

func _fire_shower(count: int):
	if not is_instance_valid(Global.player) or not shower_scene:
		return
	var dir := boss.global_position.direction_to(Global.player.global_position)
	var spread := shower_angle
	var step := spread / float(count - 1) if count > 1 else 0.0
	var start_angle := -spread / 2.0
	for i in range(count):
		var p := shower_scene.instantiate() as Projectile
		boss.get_parent().add_child(p)
		p.global_position = boss.global_position
		var angle := start_angle + step * i
		var velocity := dir.rotated(deg_to_rad(angle)) * projectile_speed
		p.rotation = velocity.angle()
		p.set_projectile(velocity, boss.stats.damage, false, 0, boss)

func _fire_golem_shot():
	if not is_instance_valid(Global.player) or not golem_scene:
		return
	var dir := boss.global_position.direction_to(Global.player.global_position)
	var p := golem_scene.instantiate() as Projectile
	boss.get_parent().add_child(p)
	p.global_position = boss.global_position
	var velocity := dir * projectile_speed
	p.rotation = velocity.angle()
	p.set_projectile(velocity, boss.stats.damage, false, 0, boss)

func _on_second_phase_started():
	in_second_phase = true
