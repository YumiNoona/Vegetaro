extends Area2D

@export var heal_amount: float = 10.0
@export var lifetime: float = 10.0  # seconds before disappearing
@export var move_speed: float = 50.0
@export var move_radius: float = 10.0

var time_alive: float = 0.0
var base_position: Vector2

func _ready() -> void:
	base_position = global_position
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Sprite2D, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	time_alive += delta
	
	# Move in a small circle
	var time = Time.get_ticks_msec() * 0.001
	position = base_position + Vector2(cos(time * 2.0) * move_radius, sin(time * 2.0) * move_radius)
	
	# Fade out near end of lifetime
	if time_alive > lifetime - 1.0:
		modulate.a = lerp(1.0, 0.0, (time_alive - (lifetime - 1.0)) / 1.0)
	
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(heal_amount)
		# Add healing effect here if needed
		queue_free()
	elif body.is_in_group("boss"):
		# Boss collects the orb
		if body.has_method("heal"):
			body.heal(heal_amount * 2)  # Boss gets more healing
		queue_free()
