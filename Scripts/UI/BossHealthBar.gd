extends Control
class_name BossHealthBar

@onready var boss_name_label: Label = $BossNameLabel
@onready var health_bar_container: Control = $HealthBarContainer
@onready var fill_rect: ColorRect = $HealthBarContainer/Fill
@onready var health_label: Label = $HealthBarContainer/HealthLabel

var boss: Boss = null
var health_material: ShaderMaterial = null
var time_offset: float = 0.0
var max_width: float = 0.0

func setup(boss_instance: Boss, boss_name: String):
	boss = boss_instance
	boss_name_label.text = boss_name
	time_offset = randf() * 10.0  # Random offset for animation variety
	
	# Store max width for scaling
	await get_tree().process_frame
	max_width = health_bar_container.size.x
	
	# Load and apply animated shader material
	var material_resource = preload("res://Shaders/BossHealthBarMaterial.tres")
	if material_resource:
		health_material = material_resource.duplicate()
		# Apply material to ColorRect which supports materials
		fill_rect.material = health_material
	
	if boss and boss.has_node("HealthComponent"):
		var health_comp = boss.get_node("HealthComponent")
		health_comp.on_health_changed.connect(_on_health_changed)
		health_comp.on_unit_died.connect(_on_boss_died)
		_update_health(health_comp.current_health, health_comp.max_health)
	
	visible = true

func _process(_delta):
	if health_material:
		health_material.set_shader_parameter("time_offset", time_offset)

func _update_health(current: float, maximum: float):
	if maximum <= 0:
		return
	
	var percent = current / maximum
	
	# Update fill width based on health percentage
	if max_width > 0:
		fill_rect.size.x = max_width * percent
		fill_rect.position.x = 0  # Keep it aligned to left
	
	# Update shader with health percent
	if health_material:
		health_material.set_shader_parameter("health_percent", percent)
	
	# Show simple percentage
	if percent >= 1.0:
		health_label.text = "100%"
	else:
		health_label.text = "%d%%" % int(percent * 100)

func _on_health_changed(current: float, maximum: float):
	_update_health(current, maximum)

func _on_boss_died():
	visible = false
	boss = null

func _exit_tree():
	if boss and boss.has_node("HealthComponent"):
		var health_comp = boss.get_node("HealthComponent")
		if health_comp.on_health_changed.is_connected(_on_health_changed):
			health_comp.on_health_changed.disconnect(_on_health_changed)
		if health_comp.on_unit_died.is_connected(_on_boss_died):
			health_comp.on_unit_died.disconnect(_on_boss_died)
