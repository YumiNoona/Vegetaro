extends Control
class_name HealthBar

@export var back_color: Color
@export var fill_color: Color

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var health_label: Label = $HealthAmount


func _ready() -> void:
	var back_style := progress_bar.get_theme_stylebox("background").duplicate()
	back_style.bg_color = back_color
	
	var fill_style := progress_bar.get_theme_stylebox("fill").duplicate()
	fill_style.bg_color = fill_color

	progress_bar.add_theme_stylebox_override("background", back_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)



func update_bar(value: float, health: float) -> void:
	progress_bar.value = value
	health_label.text = str(health)


func _on_health_component_on_health_changed(current: float, maximum: float) -> void:
	var value = current / maximum
	update_bar(value, current)
