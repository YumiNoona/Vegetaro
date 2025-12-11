extends Node2D

@export var boss: Boss
@export var bomb_scene: PackedScene
@export var bomb_damage: float = 15.0
@export var bomb_radius: float = 150.0
@export var bomb_cooldown: float = 3.0
@export var bombs_per_volley: int = 3
@export var second_phase_bombs_per_volley: int = 5

var cooldown_timer: float = 0.0
var in_second_phase := false

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		cooldown_timer = bomb_cooldown

func _process(delta):
	if Global.game_paused or not boss:
		return
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	else:
		_launch_bomb_volley()
		cooldown_timer = bomb_cooldown

func _launch_bomb_volley():
	if not boss or not bomb_scene:
		return
	
	var num_bombs = bombs_per_volley if not in_second_phase else second_phase_bombs_per_volley
	var current_damage = boss.stats.damage * 0.5  # Scale boss damage for bombs (50% of boss damage)
	
	for i in range(num_bombs):
		var bomb = bomb_scene.instantiate()
		boss.get_parent().add_child(bomb)
		
		# Position bomb near player or in pattern
		var target_pos: Vector2
		if is_instance_valid(Global.player):
			if num_bombs > 1:
				# Spread bombs around player
				var angle = (i * TAU / num_bombs) + (get_tree().get_frame() * 0.1)
				var offset = Vector2.RIGHT.rotated(angle) * 150.0
				target_pos = Global.player.global_position + offset
			else:
				target_pos = Global.player.global_position
		else:
			target_pos = boss.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		
		bomb.global_position = target_pos
		
		# Setup bomb explosion with boss's damage
		if bomb.has_method("setup_bomb"):
			bomb.setup_bomb(current_damage, bomb_radius, boss)
		elif bomb.has_node("HitboxComponent"):
			var hitbox = bomb.get_node("HitboxComponent")
			if hitbox:
				hitbox.setup(current_damage, false, 0, boss)  # damage, critical, knockback, source
		elif bomb.has_node("Area2D"):
			# Fallback for bombs with Area2D but no HitboxComponent
			bomb_damage = current_damage  # Update the instance variable for _explode_bomb
			await get_tree().create_timer(2.0).timeout
			_explode_bomb(bomb)

func _explode_bomb(bomb):
	if not is_instance_valid(bomb):
		return
	
	# Damage all enemies/player in radius
	var area = bomb.get_node("Area2D") if bomb.has_node("Area2D") else null
	if area:
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			if body.has_node("HealthComponent"):
				var health_comp = body.get_node("HealthComponent")
				health_comp.take_damage(bomb_damage, boss)  # Pass the boss as the damage source
	
	bomb.queue_free()

func _on_second_phase_started():
	in_second_phase = true
	bomb_cooldown *= 0.6  # Faster bombing
