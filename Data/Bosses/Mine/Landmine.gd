extends Area2D

@export var damage: float = 20.0

func _ready():
	add_to_group("enemies")
	print("Landmine ready!")

func _on_area_entered(area: Area2D) -> void:
	print("Landmine triggered by: ", area)
	
	if area.name == "HurtboxComponent" and area.get_parent().is_in_group("player"):
		var player = area.get_parent()
		print("Landmine: Player detected!")
		if player.health_component:
			print("Landmine: Damaging player for ", damage)
			player.health_component.take_damage(damage)
		else:
			print("Landmine: Player has no health_component!")
		queue_free()
	else:
		print("Landmine: Not a player hurtbox, ignoring.")
