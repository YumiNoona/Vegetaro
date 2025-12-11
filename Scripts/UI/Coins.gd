extends Area2D
class_name Coins

@export var move_speed := 1000.0
@export var collect_distance := 15.0

var value := 1
var target_screen_pos := Vector2.INF
var target_pos: Vector2
var collected := false

func _process(delta: float) -> void:
	if collected and target_screen_pos == Vector2.INF:
		if is_instance_valid(Global.player):
			target_pos = Global.player.global_position
	
	if target_screen_pos != Vector2.INF:
		target_pos = get_canvas_transform().affine_inverse() * target_screen_pos
	
	if target_pos != Vector2.ZERO:
		global_position = global_position.move_toward(target_pos, move_speed * delta)
	
	if global_position.distance_to(target_pos) < collect_distance:
		add_coins()


func add_coins() -> void:
	Global.coins += value
	queue_free()


func set_collection_target(screen_pos: Vector2) -> void:
	target_screen_pos = screen_pos


func _on_area_entered(_area: Area2D) -> void:
	collected = true
