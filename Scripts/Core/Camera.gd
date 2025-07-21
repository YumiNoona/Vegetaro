extends Camera2D
class_name Camera


var shake_strength := 0.0
var shake_timer := 0.0


func _process(delta: float) -> void:
	if is_instance_valid(Global.player):
		global_position = Global.player.global_position

	# Boss
	if shake_timer > 0.0:
		shake_timer -= delta
		if shake_timer > 0.0:
			global_position += Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		else:
			shake_strength = 0.0

func shake(strength: float, duration: float = 0.5):
	shake_strength = strength
	shake_timer = duration
