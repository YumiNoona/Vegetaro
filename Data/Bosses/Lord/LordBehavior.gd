extends Node2D

@export var boss: Boss
@export var lord_scene: PackedScene
@export var rain_scene: PackedScene
@export var sword_scene: PackedScene
@export var aura_scene: PackedScene
@export var lord_cooldown := 2.0
@export var rain_cooldown := 4.0
@export var rain_count := 8
@export var rain_radius := 300.0
@export var projectile_speed := 1000.0
@export var sword_speed := 600.0
@export var aura_cooldown := 6.0
@export var aura_ring_count := 12

var lord_timer := 0.0
var rain_timer := 0.0
var sword_timer := 0.0
var aura_timer := 0.0
var in_second_phase := false
var alternating := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		lord_timer = lord_cooldown
		rain_timer = rain_cooldown

func _process(delta):
	if Global.game_paused or not boss:
		return
	lord_timer -= delta
	if lord_timer <= 0:
		if not alternating:
			_fire_lord()
		else:
			_fire_rain()
		alternating = not alternating
		lord_timer = lord_cooldown if not alternating else rain_cooldown
	if in_second_phase:
		sword_timer -= delta
		if sword_timer <= 0:
			_fire_sword()
			sword_timer = lord_cooldown * 1.5
		aura_timer -= delta
		if aura_timer <= 0:
			_fire_aura()
			aura_timer = aura_cooldown

func _fire_lord():
	if not is_instance_valid(Global.player) or not lord_scene:
		return
	var dir := boss.global_position.direction_to(Global.player.global_position)
	var p := lord_scene.instantiate() as Projectile
	boss.get_parent().add_child(p)
	p.global_position = boss.global_position
	var velocity := dir * projectile_speed
	p.rotation = velocity.angle()
	p.set_projectile(velocity, boss.stats.damage, false, 0, boss)

func _fire_rain():
	if not is_instance_valid(Global.player) or not rain_scene:
		return
	var center := Global.player.global_position if is_instance_valid(Global.player) else boss.global_position
	for i in range(rain_count):
		var angle := (TAU / rain_count) * i
		var offset := Vector2.RIGHT.rotated(angle) * rain_radius
		var spawn_pos := center + offset
		var dir := (center - spawn_pos).normalized()
		var p := rain_scene.instantiate() as Projectile
		boss.get_parent().add_child(p)
		p.global_position = spawn_pos
		var velocity := dir * projectile_speed * 0.6
		p.rotation = velocity.angle()
		p.set_projectile(velocity, boss.stats.damage * 0.7, false, 0, boss)

func _fire_sword():
	if not is_instance_valid(Global.player) or not sword_scene:
		return
	var dir := boss.global_position.direction_to(Global.player.global_position)
	var p := sword_scene.instantiate() as Projectile
	boss.get_parent().add_child(p)
	p.global_position = boss.global_position
	var velocity := dir * sword_speed
	p.rotation = velocity.angle()
	p.set_projectile(velocity, boss.stats.damage * 1.2, false, 0, boss)

func _fire_aura():
	if not is_instance_valid(Global.player) or not aura_scene:
		return
	for i in range(aura_ring_count):
		var angle := (TAU / aura_ring_count) * i
		var dir := Vector2.RIGHT.rotated(angle)
		var p := aura_scene.instantiate() as Projectile
		boss.get_parent().add_child(p)
		p.global_position = boss.global_position
		var velocity := dir * projectile_speed * 0.5
		p.rotation = velocity.angle()
		p.set_projectile(velocity, boss.stats.damage * 0.5, false, 0, boss)

func _on_second_phase_started():
	in_second_phase = true
