extends Resource
class_name BossConfigResource

@export var has_second_phase: bool = false
@export var second_phase_threshold: float = 0.2 # 20% HP
@export var second_phase_hp: float = 100.0
@export var camera_shake_on_second_phase: bool = false
@export var camera_shake_strength: float = 10.0
