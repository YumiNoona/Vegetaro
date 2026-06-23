extends Node2D

@export var enemy: Enemy
@export var spawn_scene: PackedScene
@export var spawn_interval := 5.0
@export var spawn_count := 2

var cooldown := 0.0

func _ready() -> void:
	cooldown = spawn_interval

func _process(delta: float) -> void:
	if Global.game_paused or not is_instance_valid(enemy):
		return
	cooldown -= delta
	if cooldown <= 0:
		spawn()
		cooldown = spawn_interval

func spawn() -> void:
	if not spawn_scene or not is_instance_valid(enemy.get_parent()):
		return
	for i in spawn_count:
		var instance := spawn_scene.instantiate()
		enemy.get_parent().add_child(instance)
		instance.global_position = enemy.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
