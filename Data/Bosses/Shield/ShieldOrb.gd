extends Area2D

@export var health: float = 30.0
@export var contact_damage: float = 10.0
@export var destroy_effect: PackedScene

var is_active: bool = true

func _ready() -> void:
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func take_damage(amount: float) -> void:
	if not is_active:
		return
		
	health -= amount
	
	# Visual feedback when hit
	var tween = create_tween()
	self_modulate = Color.RED
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		destroy()

func destroy() -> void:
	if not is_active:
		return
		
	is_active = false
	
	# Spawn destroy effect if available
	if destroy_effect:
		var effect = destroy_effect.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	
	# Remove from parent's shields array if exists
	if get_parent().has_method("_on_shield_destroyed"):
		get_parent()._on_shield_destroyed(self)
	
	queue_free()

func set_health(value: float) -> void:
	health = value
 
func set_contact_damage(value: float) -> void:
	contact_damage = value
 
func set_destroy_effect(value: PackedScene) -> void:
	destroy_effect = value

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
		
	# Check if hit by player's attack
	if area.is_in_group("player_attack"):
		var damage = area.damage if area.has_method("get_damage") else 10.0
		take_damage(damage)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
		
	# Deal contact damage to player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
			
			# Small knockback
			var knockback_direction = (body.global_position - global_position).normalized()
			if body.has_method("apply_knockback"):
				body.apply_knockback(knockback_direction * 200.0)
