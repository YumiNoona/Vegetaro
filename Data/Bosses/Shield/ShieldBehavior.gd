extends Node2D

@export var boss: Node2D
@export var shield_scene: PackedScene = preload("res://Data/Bosses/Shield/ShieldOrb.tscn")
@export var num_shields: int = 3
@export var shield_radius: float = 150.0
@export var rotation_speed: float = 2.0
@export var second_phase_rotation_speed: float = 5.0
@export var shield_damage_multiplier: float = 0.5
@export var shield_health: float = 30.0
@export var contact_damage: float = 10.0
@export var projectile_reflect_chance: float = 0.3
@export var projectile_reflect_damage_multiplier: float = 1.5
@export var shield_respawn_time: float = 10.0  # Time to respawn shields in seconds

var shields: Array[Node2D] = []
var dead_shields: Array[Node2D] = []
var in_second_phase := false
var current_rotation_speed: float
var respawn_timer: float = 0.0
var is_respawning: bool = false

func _ready() -> void:
	if boss:
		if boss.has_signal("second_phase_started"):
			boss.second_phase_started.connect(_on_second_phase_started)
		boss.tree_exiting.connect(_on_boss_exiting)
		_spawn_shields()
		current_rotation_speed = rotation_speed

func _process(delta: float) -> void:
	if Global.game_paused or not is_instance_valid(boss):
		return
	
	# Handle shield respawning
	if is_respawning:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn_shields()
			is_respawning = false
	
	# Update shield positions
	if not shields.is_empty():
		var _angle_step = TAU / max(1, shields.size() + dead_shields.size())
		var active_shield_count = 0
		
		for i in range(shields.size() - 1, -1, -1):
			var shield = shields[i]
			if not is_instance_valid(shield):
				shields.remove_at(i)
				continue
			
			var total_shields = shields.size() + dead_shields.size()
			var angle = (Time.get_ticks_msec() * 0.001 * current_rotation_speed) + (i * TAU / max(1, total_shields))
			var offset = Vector2.RIGHT.rotated(angle) * shield_radius
			shield.global_position = boss.global_position + offset
			shield.rotation = angle + PI/2
			active_shield_count += 1
		
		# If all shields are destroyed, start respawn timer
		if active_shield_count == 0 and not is_respawning and dead_shields.size() > 0:
			start_shield_respawn()

func _spawn_shields() -> void:
	if not is_instance_valid(boss) or not shield_scene:
		return
	
	shields.clear()
	dead_shields.clear()
	
	for i in range(num_shields):
		var shield = shield_scene.instantiate()
		
		# Set up shield properties
		if shield.has_method("set_health"):
			shield.set_health(shield_health)
		if shield.has_method("set_contact_damage"):
			shield.contact_damage = contact_damage
		if shield.has_method("set_destroy_effect"):
			shield.destroy_effect = preload("uid://ccmb0mkbxs1xa")
		
		# Connect to shield's signals if they exist
		if shield.has_signal("shield_destroyed"):
			shield.shield_destroyed.connect(_on_shield_destroyed.bind(shield))
		
		# Only add to the scene once
		if is_instance_valid(boss.get_parent()):
			boss.get_parent().add_child(shield)
			shields.append(shield)
			
			# Set up collision signals
			if shield.has_node("Area2D"):
				var area = shield.get_node("Area2D")
				if area.has_signal("body_entered") and not area.body_entered.is_connected(_on_shield_body_entered.bind(shield)):
					area.body_entered.connect(_on_shield_body_entered.bind(shield))
				
				if area.has_signal("area_entered") and not area.area_entered.is_connected(_on_shield_area_entered.bind(shield)):
					area.area_entered.connect(_on_shield_area_entered.bind(shield))

func _on_shield_body_entered(body: Node, shield: Node) -> void:
	if not is_instance_valid(boss) or body != Global.player or not body.has_node("HealthComponent"):
		return
	
	var health_comp = body.get_node("HealthComponent")
	if health_comp:
		health_comp.take_damage(contact_damage, boss)
		_show_hit_effect(shield.global_position)

func _on_shield_area_entered(area: Area2D, shield: Node) -> void:
	if not is_instance_valid(boss) or not area.is_in_group("player_projectiles"):
		return
	
	var current_health = shield.get_meta("health", shield_health)
	var damage = area.get("damage") if area.get("damage") else 10
	current_health -= damage
	shield.set_meta("health", current_health)
	
	_show_hit_effect(area.global_position)
	
	if current_health <= 0:
		_destroy_shield(shield)
	elif randf() < projectile_reflect_chance:
		_reflect_projectile(area)
	
	if is_instance_valid(area):
		area.queue_free()

func _destroy_shield(shield: Node) -> void:
	if is_instance_valid(shield):
		_show_shield_break(shield.global_position)
		var index = shields.find(shield)
		if index != -1:
			shields.remove_at(index)
		shield.queue_free()

func _reflect_projectile(projectile: Node) -> void:
	if not is_instance_valid(projectile) or not is_instance_valid(Global.player):
		return
	
	if projectile.has_method("set_direction"):
		var direction = (Global.player.global_position - projectile.global_position).normalized()
		projectile.set_direction(-direction)
		
		if projectile.has_method("set_damage"):
			var current_damage = projectile.get("damage") if projectile.get("damage") else 10
			projectile.set("damage", current_damage * projectile_reflect_damage_multiplier)
		
		projectile.set_collision_mask_value(1, true)
		projectile.set_collision_mask_value(2, false)

func _show_hit_effect(_position: Vector2) -> void:
	pass

func _show_shield_break(_position: Vector2) -> void:
	pass

func _on_shield_destroyed(shield: Node2D) -> void:
	if shield in shields:
		shields.erase(shield)
		dead_shields.append(shield)
		
		# If all shields are destroyed, start respawn timer
		if shields.is_empty() and not is_respawning:
			start_shield_respawn()

func start_shield_respawn() -> void:
	if dead_shields.is_empty():
		return
		
	is_respawning = true
	respawn_timer = shield_respawn_time
	
	# Visual feedback for respawn
	if is_instance_valid(boss) and boss.has_method("show_shield_recharge_effect"):
		boss.show_shield_recharge_effect()

func _respawn_shields() -> void:
	if dead_shields.is_empty():
		return
		
	for shield in dead_shields:
		if is_instance_valid(shield):
			shield.health = shield_health
			shield.is_active = true
			shield.visible = true
			shields.append(shield)
			
			# Visual feedback for respawned shield
			var tween = create_tween()
			shield.modulate = Color(1, 1, 1, 0)
			tween.tween_property(shield, "modulate", Color.WHITE, 0.5)
	
	dead_shields.clear()

func _on_second_phase_started() -> void:
	in_second_phase = true
	current_rotation_speed = second_phase_rotation_speed
	
	# Double the number of shields in second phase
	if shields.size() + dead_shields.size() < num_shields * 2:
		var additional_shields = num_shields
		for i in range(additional_shields):
			var shield = shield_scene.instantiate()
			shield.add_to_group("boss_shields")
			shield.set_meta("health", shield_health)
			
			# Set up shield properties using call_deferred
			if shield.has_method("set_health"):
				shield.call_deferred("set_health", shield_health)
			if shield.has_method("set_contact_damage"):
				shield.call_deferred("set", "contact_damage", contact_damage)
			if shield.has_method("set_destroy_effect"):
				shield.call_deferred("set", "destroy_effect", preload("uid://ccmb0mkbxs1xa"))
			
			# Add to scene using call_deferred
			if is_instance_valid(boss) and is_instance_valid(boss.get_parent()):
				boss.get_parent().call_deferred("add_child", shield)
				call_deferred("_setup_shield_signals", shield)
				shields.append(shield)

# New helper function to set up shield signals
func _setup_shield_signals(shield: Node) -> void:
	if not is_instance_valid(shield) or not shield.has_node("Area2D"):
		return
		
	var area = shield.get_node("Area2D")
	if area.has_signal("body_entered") and not area.body_entered.is_connected(_on_shield_body_entered.bind(shield)):
		area.body_entered.connect(_on_shield_body_entered.bind(shield))
	if area.has_signal("area_entered") and not area.area_entered.is_connected(_on_shield_area_entered.bind(shield)):
		area.area_entered.connect(_on_shield_area_entered.bind(shield))

func _on_boss_exiting() -> void:
	for shield in shields:
		if is_instance_valid(shield):
			shield.queue_free()
	shields.clear()
	
	if is_instance_valid(boss):
		if boss.has_signal("second_phase_started") and boss.second_phase_started.is_connected(_on_second_phase_started):
			boss.second_phase_started.disconnect(_on_second_phase_started)
		if boss.tree_exiting.is_connected(_on_boss_exiting):
			boss.tree_exiting.disconnect(_on_boss_exiting)

func _exit_tree() -> void:
	_on_boss_exiting()
