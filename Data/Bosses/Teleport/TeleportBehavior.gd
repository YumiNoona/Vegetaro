extends Node

@export var boss: Boss
@export var teleport_cooldown: float = 4.0
@export var teleport_distance: float = 400.0

var in_second_phase := false
var cooldown_timer := 0.0

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)

func _on_second_phase_started():
	in_second_phase = true
	cooldown_timer = teleport_cooldown

func _process(delta):
	if Global.game_paused:
		return

	if in_second_phase:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			_teleport()
			cooldown_timer = teleport_cooldown

func _teleport():
	var angle = randf_range(0, TAU)
	var offset = Vector2.RIGHT.rotated(angle) * teleport_distance
	boss.global_position += offset
