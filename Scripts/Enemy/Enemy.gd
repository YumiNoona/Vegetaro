extends Unit
class_name Enemy

@export var flock_push := 20.0

@onready var vision_area: Area2D = $VisionArea
@onready var knockback_timer: Timer = $KnockbackTimer

var can_move := true
var knockback_dir : Vector2
var knockback_power : float

func _ready() -> void:
	add_to_group("enemies")
	# ...any other setup...

func _process(delta: float) -> void:
	if Global.game_paused: return
	if not can_move: return
	if not can_move_toward_player(): return

	var move_vec = (get_move_direction() + knockback_dir * knockback_power) * stats.speed * delta
	position += move_vec
	update_rotation()

func get_move_direction() -> Vector2:
	if not is_instance_valid(Global.player):
		return Vector2.ZERO

	var direction := global_position.direction_to(Global.player.global_position)
	for area: Node2D in vision_area.get_overlapping_areas():
		if area != self and area.is_inside_tree():
			var vector := global_position - area.global_position
			direction += flock_push * vector.normalized() / vector.length()
	return direction

func update_rotation() -> void:
	if not is_instance_valid(Global.player):
		return

	var player_pos := Global.player.global_position
	var moving_right := global_position.x < player_pos.x
	visuals.scale = Vector2(-0.5, 0.5) if moving_right else Vector2(0.5, 0.5)

func can_move_toward_player() -> bool:
	return is_instance_valid(Global.player) and global_position.distance_to(Global.player.global_position) > 60

func apply_knockback(knock_dir: Vector2, knock_power : float) -> void:
	knockback_dir = knock_dir
	knockback_power = knock_power
	if knockback_timer.time_left > 0:
		knockback_timer.stop()
		reset_knockback()
	knockback_timer.start()

func reset_knockback() -> void:
	knockback_dir = Vector2.ZERO
	knockback_power = 0.0

func _on_knockback_timer_timeout() -> void:
	reset_knockback()

func _on_hurtbox_component_on_damaged(hitbox: HitboxComponent) -> void:
	super._on_hurtbox_component_on_damaged(hitbox)
	if hitbox.knockback_power > 0:
		var dir := hitbox.source.global_position.direction_to(global_position)
		apply_knockback(dir, hitbox.knockback_power)

func _on_health_component_on_unit_died() -> void:
	Global.on_enemy_died.emit(self)

func destroy_enemy() -> void:
	can_move = false
	if anim_player and anim_player.has_animation("Death"):
		anim_player.play("Death")
		await anim_player.animation_finished
	queue_free()
