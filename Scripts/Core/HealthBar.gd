extends Control
class_name HealthBar

@export var back_color: Color
@export var fill_color: Color

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var health_label: Label = $HealthAmount


func _ready() -> void:
	var back_stylebox = progress_bar.get_theme_stylebox("background")
	if back_stylebox:
		var back_style := back_stylebox.duplicate()
		back_style.bg_color = back_color
		progress_bar.add_theme_stylebox_override("background", back_style)
	
	var fill_stylebox = progress_bar.get_theme_stylebox("fill")
	if fill_stylebox:
		var fill_style := fill_stylebox.duplicate()
		fill_style.bg_color = fill_color
		progress_bar.add_theme_stylebox_override("fill", fill_style)



func update_bar(value: float, health: float) -> void:
	progress_bar.value = value
	health_label.text = str(health)


func _on_health_component_on_health_changed(current: float, maximum: float) -> void:
	if maximum <= 0:
		return
	var value = current / maximum
	update_bar(value, current)
