extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Play the explosion animation
	animation_player.play("explode")
	# Connect the animation finished signal
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_anim_name: String) -> void:
	# Remove the explosion when the animation is done
	queue_free()

# Function to set the size of the explosion
func set_explosion_size(size: float) -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = size / 2

# Function to set the damage of the explosion
func set_damage(damage_amount: float) -> void:
	# If you want to add damage functionality later
	pass
