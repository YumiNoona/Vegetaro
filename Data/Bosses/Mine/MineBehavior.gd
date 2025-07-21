extends Node

@export var boss: Boss
@export var mine_scene: PackedScene
@export var mine_cooldown: float = 3.0
@export var max_mines: int = 5

var in_second_phase := false
var cooldown_timer := 0.0
var mines_placed := 0

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)

func _on_second_phase_started():
	in_second_phase = true
	cooldown_timer = mine_cooldown
	mines_placed = 0

func _process(delta):
	if in_second_phase and mines_placed < max_mines:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			_place_mine()
			cooldown_timer = mine_cooldown

func _place_mine():
	var mine = mine_scene.instantiate()
	mine.global_position = boss.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	mine.add_to_group("enemies")  # 🧠 So clear_enemies() will clean it
	boss.get_tree().root.call_deferred("add_child", mine)
