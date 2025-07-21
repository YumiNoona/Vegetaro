extends Line2D
class_name  Trail

@export var player: Player
@export var trail_lenght := 25
@export var trail_duration := 1.0


@onready var trail_timer: Timer = %TrailTimer


var points_array : Array[Vector2] = []
var is_active := false

func _process(_delta: float) -> void:
	if not is_active:
		return
	
	points_array.append(player.global_position)
	if points_array.size() > trail_lenght:
		points_array.pop_front()
	
	points = points_array


func start_trail() -> void:
	is_active = true
	clear_points()
	points_array.clear()
	trail_timer.start(trail_duration)


func _on_trail_timer_timeout() -> void:
	is_active = false
	clear_points()
	points_array.clear()
	
