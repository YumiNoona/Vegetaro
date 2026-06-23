extends Node2D

@export var boss: Boss
@export var normal_scene: PackedScene
@export var lock_scene: PackedScene
@export var normal_count := 3
@export var normal_angle := 20.0
@export var normal_cooldown := 2.5
@export var lock_count := 2
@export var lock_cooldown := 3.0
@export var projectile_speed := 900.0
@export var lock_speed := 400.0
@export var lock_homing_strength := 3.0

var normal_timer := 0.0
var lock_timer := 0.0
var in_second_phase := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		normal_timer = normal_cooldown
		lock_timer = lock_cooldown

func _process(delta):
	if Global.game_paused or not boss:
		return
	normal_timer -= delta
	if normal_timer <= 0:
		_fire_normal()
		normal_timer = normal_cooldown
	if in_second_phase:
		lock_timer -= delta
		if lock_timer <= 0:
			_fire_lock()
			lock_timer = lock_cooldown

func _fire_normal():
	if not is_instance_valid(Global.player) or not normal_scene:
		return
	var dir := boss.global_position.direction_to(Global.player.global_position)
	var step := normal_angle / float(normal_count - 1) if normal_count > 1 else 0.0
	var start_angle := -normal_angle / 2.0
	for i in range(normal_count):
		var p := normal_scene.instantiate() as Projectile
		boss.get_parent().add_child(p)
		p.global_position = boss.global_position
		var angle := start_angle + step * i
		var velocity := dir.rotated(deg_to_rad(angle)) * projectile_speed
		p.rotation = velocity.angle()
		p.set_projectile(velocity, boss.stats.damage, false, 0, boss)

func _fire_lock():
	if not is_instance_valid(Global.player) or not lock_scene:
		return
	for i in range(lock_count):
		var p := lock_scene.instantiate() as Projectile
		boss.get_parent().add_child(p)
		p.global_position = boss.global_position
		var offset_angle := deg_to_rad(10.0 * (i - (lock_count - 1) / 2.0))
		var dir := boss.global_position.direction_to(Global.player.global_position).rotated(offset_angle)
		var velocity := dir * lock_speed
		p.rotation = velocity.angle()
		p.set_projectile(velocity, boss.stats.damage, false, 0, boss)

func _on_second_phase_started():
	in_second_phase = true
