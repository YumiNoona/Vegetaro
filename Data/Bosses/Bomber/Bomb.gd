extends Node2D

@export var damage: float = 15.0
@export var radius: float = 150.0
@export var source: Node2D
@export var random_position_range: float = 100.0  # How far from center bombs can spawn

@onready var hitbox_component: Node = $HitboxComponent
@onready var timer: Timer = $Timer

var _is_exploded := false

func _ready() -> void:
	# Make sure we have a hitbox component
	if not hitbox_component and has_node("HitboxComponent"):
		hitbox_component = $HitboxComponent
	
	# Connect to the hitbox's body_entered signal if it exists
	if hitbox_component and hitbox_component.has_signal("body_entered"):
		if not hitbox_component.body_entered.is_connected(_on_body_entered):
			hitbox_component.body_entered.connect(_on_body_entered)

func setup_bomb(dmg: float, rad: float, src: Node2D) -> void:
	damage = dmg
	radius = rad
	source = src
	
	# Apply random offset
	var random_offset = Vector2(
		randf_range(-random_position_range, random_position_range),
		randf_range(-random_position_range, random_position_range)
	)
	position += random_offset

	# Set up collision shape if it exists
	if hitbox_component and hitbox_component.has_node("CollisionShape2D"):
		var cs_node = hitbox_component.get_node("CollisionShape2D")
		if cs_node.shape is CircleShape2D:
			cs_node.shape.radius = radius
	
	# Start the timer as a backup in case player doesn't step on it
	if timer and not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

func _on_body_entered(body: Node) -> void:
	if _is_exploded or not body == Global.player:
		return
	_explode()

func _on_timer_timeout() -> void:
	_explode()

func _explode() -> void:
	if _is_exploded:
		return
		
	_is_exploded = true
	
	# Clean up signals
	if hitbox_component and hitbox_component.body_entered.is_connected(_on_body_entered):
		hitbox_component.body_entered.disconnect(_on_body_entered)
	
	if timer and timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.disconnect(_on_timer_timeout)
	
	# Damage player if in range
	if is_inside_tree() and hitbox_component:
		var bodies = hitbox_component.get_overlapping_bodies()
		for body in bodies:
			if body == Global.player and body.has_node("HealthComponent"):
				var health_comp = body.get_node("HealthComponent")
				if health_comp.has_method("take_damage"):
					health_comp.take_damage(damage, source if source else null)
	
	# Remove the bomb
	queue_free()

func _exit_tree() -> void:
	# Clean up signal connections
	if hitbox_component and hitbox_component.body_entered.is_connected(_on_body_entered):
		hitbox_component.body_entered.disconnect(_on_body_entered)
	if timer and timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.disconnect(_on_timer_timeout)
