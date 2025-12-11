extends Unit
class_name Player

signal on_dash

@export var dash_duration := 0.5
@export var dash_speed_multi := 2.0
@export var dash_cooldown := 1.5

@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var trail: Trail = %Trail
@onready var weapon_container: WeaponContainer = $WeaponContainer

var current_weapons: Array[Weapon] = []
var move_dir: Vector2
var is_dashing := false
var dash_available := true
var joystick: VirtualJoystick = null

# --- MOMENTUM ---
var momentum_stacks := 0
var momentum_timer: Timer = null
const MOMENTUM_MAX_STACKS := 5
const MOMENTUM_STACK_SPEED := 10
const MOMENTUM_STACK_DURATION := 3.0

func enable_momentum():
	if not Global.is_connected("on_enemy_died", Callable(self, "_on_momentum_enemy_killed")):
		Global.connect("on_enemy_died", Callable(self, "_on_momentum_enemy_killed"))

func _on_momentum_enemy_killed(_enemy):
	momentum_stacks = min(momentum_stacks + 1, MOMENTUM_MAX_STACKS)
	stats.speed += MOMENTUM_STACK_SPEED
	if momentum_timer:
		momentum_timer.stop()
	else:
		momentum_timer = Timer.new()
		add_child(momentum_timer)
	momentum_timer.wait_time = MOMENTUM_STACK_DURATION
	momentum_timer.one_shot = true
	if not momentum_timer.timeout.is_connected(_on_momentum_timer_timeout):
		momentum_timer.timeout.connect(_on_momentum_timer_timeout)
		momentum_timer.start()

func _on_momentum_timer_timeout():
	stats.speed -= MOMENTUM_STACK_SPEED * momentum_stacks
	momentum_stacks = 0

# --- GLASS CANNON ---
func enable_glass_cannon():
	stats.damage *= 2
	stats.health *= 0.5
	health_component.setup(stats)

# --- STATIC FIELD ---
var static_field_timer: Timer = null
const STATIC_FIELD_INTERVAL := 5.0
const STATIC_FIELD_RADIUS := 200.0
const STATIC_FIELD_DAMAGE := 20.0

func enable_static_field():
	if not static_field_timer:
		static_field_timer = Timer.new()
		static_field_timer.wait_time = STATIC_FIELD_INTERVAL
		static_field_timer.autostart = true
		static_field_timer.timeout.connect(_on_static_field_burst)
		add_child(static_field_timer)
		static_field_timer.start()

func _on_static_field_burst():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and position.distance_to(enemy.position) <= STATIC_FIELD_RADIUS:
			if enemy.has_node("HealthComponent"):
				enemy.get_node("HealthComponent").take_damage(STATIC_FIELD_DAMAGE)

# --- RETALIATION ---
var retaliation_timer: Timer = null
const RETALIATION_BUFF := 0.2
const RETALIATION_DURATION := 5.0
var retaliation_active := false

func enable_retaliation():
	if not health_component.on_unit_hit.is_connected(_on_retaliation_hit):
		health_component.on_unit_hit.connect(_on_retaliation_hit)

func _on_retaliation_hit(_hitbox):
	if not retaliation_active:
		stats.damage *= (1.0 + RETALIATION_BUFF)
		retaliation_active = true
		if not retaliation_timer:
			retaliation_timer = Timer.new()
			add_child(retaliation_timer)
		retaliation_timer.wait_time = RETALIATION_DURATION
		retaliation_timer.one_shot = true
		if not retaliation_timer.timeout.is_connected(_on_retaliation_timer_timeout):
			retaliation_timer.timeout.connect(_on_retaliation_timer_timeout)
		retaliation_timer.start()

func _on_retaliation_timer_timeout():
	stats.damage /= (1.0 + RETALIATION_BUFF)
	retaliation_active = false

# --- UNSTOPPABLE ---
var unstoppable_timer: Timer = null
const UNSTOPPABLE_SPEED_THRESHOLD := 0.99
const UNSTOPPABLE_DURATION := 2.0
var unstoppable_active := false

func enable_unstoppable():
	set_process(true)

func _ready() -> void:
	super._ready()
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	Global.player = self
	
	# Connect health component death signal (in case it's not connected in scene)
	if health_component and not health_component.on_unit_died.is_connected(_on_health_component_on_unit_died):
		health_component.on_unit_died.connect(_on_health_component_on_unit_died)
	
	# Find joystick if it exists (for mobile)
	_find_joystick()

func _find_joystick() -> void:
	# Look for joystick in the scene tree
	var tree = get_tree()
	if tree:
		var joystick_node = tree.get_first_node_in_group("joystick")
		if joystick_node and joystick_node is VirtualJoystick:
			joystick = joystick_node
			joystick.movement_changed.connect(_on_joystick_movement_changed)
		else:
			# Try to find it by searching the tree
			joystick = _search_for_joystick(tree.root)

func _search_for_joystick(node: Node) -> VirtualJoystick:
	if node is VirtualJoystick:
		return node as VirtualJoystick
	for child in node.get_children():
		var result = _search_for_joystick(child)
		if result:
			return result
	return null

func _on_joystick_movement_changed(_direction: Vector2) -> void:
	# This will be called when joystick movement changes
	# The actual movement will be handled in _process
	pass

func _process(delta: float) -> void:
	# Unstoppable logic
	if stats.speed > 0 and move_dir.length() > 0:
		var current_speed = move_dir.length()
		if current_speed >= stats.speed * UNSTOPPABLE_SPEED_THRESHOLD:
			if not unstoppable_active:
				if not unstoppable_timer:
					unstoppable_timer = Timer.new()
					add_child(unstoppable_timer)
				unstoppable_timer.wait_time = UNSTOPPABLE_DURATION
				unstoppable_timer.one_shot = true
				unstoppable_timer.timeout.connect(_on_unstoppable_timer_timeout)
				unstoppable_timer.start()
				unstoppable_active = true
				# Add CC immunity flag here
		else:
			if unstoppable_active:
				unstoppable_active = false
				# Remove CC immunity flag here

	# Movement and dash logic
	# Use joystick input if available and visible, otherwise use keyboard input
	if joystick and joystick.visible:
		var joystick_dir = joystick.get_movement_direction()
		# Use joystick if it's providing input, otherwise fall back to keyboard
		if joystick_dir.length() > 0.1:
			move_dir = joystick_dir
		else:
			move_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")
	else:
		move_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")

	if Global.game_paused:
		return

	var current_velocity := move_dir * stats.speed
	if is_dashing:
		current_velocity *= dash_speed_multi

	position += current_velocity * delta
	position.x = clamp(position.x, -1000, 1000)
	position.y = clamp(position.y, -500, 500)

	if can_dash():
		start_dash()

	update_animations()
	update_rotation()

func _on_unstoppable_timer_timeout():
	unstoppable_active = false
	# Remove CC immunity flag here

func can_dash() -> bool:
	return not is_dashing \
		and dash_cooldown_timer.is_stopped() \
		and Input.is_action_just_pressed("Dash") \
		and move_dir != Vector2.ZERO

func start_dash() -> void:
	is_dashing = true
	dash_timer.start()
	trail.start_trail()
	visuals.modulate.a = 0.5
	collision.set_deferred("disabled", true)
	emit_signal("on_dash")

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	visuals.modulate.a = 1.0
	move_dir = Vector2.ZERO
	collision.set_deferred("disabled", false)
	dash_cooldown_timer.start()

func add_weapon(data: ItemWeapon) -> void:
	var weapon: Weapon = data.scene.instantiate()
	add_child(weapon)
	weapon.setup_weapon(data)
	current_weapons.append(weapon)
	weapon_container.update_weapons_position(current_weapons)

func update_animations() -> void:
	if move_dir.length() > 0:
		anim_player.play("Move")
	else:
		anim_player.play("Idle")

func update_rotation() -> void:
	if move_dir == Vector2.ZERO:
		return
	visuals.scale = Vector2(-0.5, 0.5) if move_dir.x >= 0.1 else Vector2(0.5, 0.5)

func is_facing_right() -> bool:
	return visuals.scale.x == -0.5

func update_player_new_wave() -> void:
	stats.health += stats.health_increased_Per_wave
	health_component.setup(stats)

func _on_hp_regen_timer_timeout() -> void:
	if health_component.current_health <= 0:
		return
	if health_component.current_health < stats.health:
		var heal = stats.hp_regen
		health_component.heal(heal)
		Global.on_create_heal_text.emit(self, heal)

func _on_health_component_on_unit_died() -> void:
	Global.player = null
	Global.game_paused = true
	
	# Signal to Arena to show game over panel immediately (before animation)
	Global.on_player_died.emit()
	
	# Stop all timers and spawners immediately
	var arena = get_tree().get_first_node_in_group("arena")
	if arena and arena.has_node("Spawner"):
		var spawner = arena.get_node("Spawner")
		spawner.spawn_timer.stop()
		spawner.wave_timer.stop()
	
	anim_player.play("Death")
	await anim_player.animation_finished
	queue_free()
