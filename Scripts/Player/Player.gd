extends Unit
class_name Player

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

func _ready() -> void:
	super._ready()
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown

func _process(delta: float) -> void:
	move_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")

	if Global.game_paused: return

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
	print("Player death handler called!")
	Global.player = null
	anim_player.play("Death")
	await anim_player.animation_finished
	queue_free()

	if not get_tree().root.has_node("GameOverPanel"):
		var game_over_panel = Global.game_over_ui_scene.instantiate()
		game_over_panel.name = "GameOverPanel"
		get_tree().root.add_child(game_over_panel)
		get_tree().paused = true
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
