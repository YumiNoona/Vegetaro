extends Node2D
class_name Weapon

@onready var sprite: Sprite2D = $Sprite2D
@onready var cooldown_timer: Timer = $CoolDownTimer
@onready var collision: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var weapon_behavior: WeaponBehavior = $WeaponBehavior

var data : ItemWeapon
var is_attacking := false
var atk_start_pos : Vector2
var targets : Array[Enemy]
var closest_target : Enemy
var weapon_spread : float

func _ready() -> void:
	atk_start_pos = sprite.position
	weapon_behavior.weapon = self

func _process(_delta: float) -> void:
	if Global.game_paused: return
	
	if not is_attacking:
		if targets.size() > 0:
			update_closest_target()
		else:
			closest_target = null
			
	rotate_to_target()
	update_visuals()


	if can_use_weapon():
		use_weapon()

func setup_weapon(weapon_data: ItemWeapon) -> void:
	self.data = weapon_data
	collision.shape.radius = weapon_data.stats.max_range
	apply_tier_outline()

func use_weapon() -> void:
	calculate_spread()
	weapon_behavior.execute_attack()
	cooldown_timer.wait_time = data.stats.cooldown
	cooldown_timer.start()


func rotate_to_target() -> void:
	if is_attacking:
		rotation = get_custom_rotation_to_target()
	else:
		rotation = get_rotation_to_target()


func get_custom_rotation_to_target() -> float:
	if not closest_target or not is_instance_valid(closest_target):
		return rotation
		
	var rot := global_position.direction_to(closest_target.global_position).angle()
	return rot + weapon_spread



func get_rotation_to_target() -> float:
	if targets.size() == 0:
		return get_idle_rotation()
		
	var rot := global_position.direction_to(closest_target.global_position).angle()
	return rot



func get_idle_rotation() -> float:
	if Global.player and Global.player.is_facing_right():
		return 0
	else:
		return PI


func update_visuals() -> void:
	if abs(rotation) > PI / 2:
		sprite.scale.y = - 0.5
	else:
		sprite.scale.y = 0.5


func calculate_spread() -> void:
	weapon_spread += randf_range(-1 + data.stats.accuracy, 1 - data.stats.accuracy)
	rotation += weapon_spread	
	
	

func update_closest_target() -> void:
	closest_target = get_closest_target()


func get_closest_target() -> Node2D:
	if targets.size() == 0:
		return
	
	var closest_enemy := targets[0]
	var closest_distance := global_position.distance_to(closest_enemy.global_position)

	for i in range(1, targets.size()):
		var target: Enemy = targets[i]
		var distance := global_position.distance_to(target.global_position)
		
		if distance < closest_distance:
			closest_enemy = target
			closest_distance = distance
			
	return closest_enemy


func can_use_weapon() -> bool:
	return cooldown_timer.is_stopped() and closest_target


func apply_tier_outline() -> void:
	if data.item_tier == Global.UpgradeTier.COMMON:
		sprite.material = null
		return
	
	var outline_color := Global.TIER_COLORS[data.item_tier]
	sprite.material.set_shader_parameter("outline_color", outline_color)


func _on_range_area_area_entered(area: Area2D) -> void:
	targets.push_back(area)


func _on_range_area_area_exited(area: Area2D) -> void:
	targets.erase(area)
	if targets.size() == 0:
		closest_target = null
