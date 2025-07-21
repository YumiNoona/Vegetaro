extends Camera2D
class_name Camera

func _process(_delta: float) -> void:
	if is_instance_valid(Global.player):
		global_position = Global.player.global_position
