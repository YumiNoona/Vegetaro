extends Node2D
class_name WeaponContainer

@onready var slot_one: Node2D = $SlotOne
@onready var slot_two: Node2D = $SlotTwo
@onready var slot_three: Node2D = $SlotThree
@onready var slot_four: Node2D = $SlotFour
@onready var slot_five: Node2D = $SlotFive
@onready var slot_six: Node2D = $SlotSix

func update_weapons_position(weapons : Array[Weapon]) -> void:
	var count := weapons.size()
	var reference_node: Node2D
	match count:
		1:reference_node = slot_one
		2:reference_node = slot_two
		3:reference_node = slot_three
		4:reference_node = slot_four
		5:reference_node = slot_five
		6:reference_node = slot_six

	var markers := reference_node.get_children()
	if markers.size() != count:
		return
		
	for i in count:
		weapons[i].global_position = markers[i].global_position
