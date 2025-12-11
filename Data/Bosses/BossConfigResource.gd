extends Resource
class_name BossConfigResource

@export var has_second_phase: bool = false
@export var second_phase_threshold: float = 0.2 # 20% HP
@export var second_phase_hp: float = 100.0
@export var camera_shake_on_second_phase: bool = false
@export var camera_shake_strength: float = 10.0
@export var second_phase_speed: float = 400.0
@export var second_phase_attack: float = 20.0
@export var second_phase_scale: float = 1.5
@export var second_phase_pulse_speed: float = 5.0
@export var second_phase_glow_color: Color = Color(0.7, 0, 0) # dark red
@export var second_phase_material: ShaderMaterial
