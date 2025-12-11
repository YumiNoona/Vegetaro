extends Node2D
class_name FLoatingText

@onready var value_label: Label = $ValueLabel

func setup (value: String, color: Color) -> void:
	value_label.text = value
	modulate = color
	scale = Vector2.ZERO

	rotation = deg_to_rad(randf_range(-10,10))
	var random_scale := randf_range(0.8,1.6)

	#Used For Smooth Animation

	var tween := create_tween()

	tween.parallel().tween_property(self, "scale", random_scale * Vector2.ONE, 0.5)
	tween.parallel().tween_property(self, "global_position", global_position + Vector2.UP * 15, 0.5)

	tween.tween_interval(0.5)

	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5) 

	await tween.finished
	queue_free()
