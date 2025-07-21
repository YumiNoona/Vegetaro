extends Node2D
class_name ChargerBehavior

@export var enemy: Enemy
@export var anim_effects: AnimationPlayer
@export var prep_time := 1.0
@export var cooldown := 3.0
@export var stop_distance := 30

var current_cooldown := 0.0
var charge_attack_position := Vector2.ZERO
var is_charging := false

func _ready() -> void:
	current_cooldown = cooldown

func _process(delta: float) -> void:
	if enemy == null:
		return

	if is_charging:
		# Move towards charge target
		enemy.global_position = enemy.global_position.move_toward(
			charge_attack_position,
			enemy.stats.speed * 5 * delta
		)

		# If close enough to target position, end the charge
		if enemy.global_position.distance_to(charge_attack_position) < stop_distance:
			end_charge()
	else:
		# Countdown before next charge
		if current_cooldown > 0:
			current_cooldown -= delta
		else:
			# Trigger charge if player is valid and far enough
			if is_instance_valid(Global.player):
				var dist = enemy.global_position.distance_to(Global.player.global_position)
				if dist > stop_distance:
					charge_attack_position = Global.player.global_position
					await start_charge()


func start_charge() -> void:
	enemy.can_move = false
	anim_effects.play("Charge")
	await anim_effects.animation_finished
	is_charging = true

func end_charge() -> void:
	is_charging = false
	current_cooldown = cooldown
	enemy.can_move = true
