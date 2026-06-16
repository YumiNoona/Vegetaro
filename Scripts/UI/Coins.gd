extends Area2D
class_name Coins

@export var move_speed := 1000.0
@export var collect_distance := 15.0

var value := 1
var target_screen_pos := Vector2.INF
var target_pos: Vector2
var has_target := false
var collected := false

func _process(delta: float) -> void:
	if collected and target_screen_pos == Vector2.INF:
		if is_instance_valid(Global.player):
			target_pos = Global.player.global_position
			has_target = true
	
	if target_screen_pos != Vector2.INF:
		target_pos = get_canvas_transform().affine_inverse() * target_screen_pos
	
	if has_target:
		global_position = global_position.move_toward(target_pos, move_speed * delta)
	
	if has_target and global_position.distance_to(target_pos) < collect_distance:
		add_coins()


func add_coins() -> void:
	Global.coins += value
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)
	tween.tween_callback(queue_free)


func set_collection_target(screen_pos: Vector2) -> void:
	target_screen_pos = screen_pos
	has_target = true


func _on_area_entered(_area: Area2D) -> void:
	collected = true
