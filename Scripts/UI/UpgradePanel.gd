extends Panel
class_name UpgradePanel


@onready var items_container: HBoxContainer = %ItemsContainer
const UPGRADE_CARD_SCENE = preload("res://Scenes/UI/Upgrade/UpgradeCard.tscn")

@export var upgrade_list : Array[ItemUpgrade]



func _animate_card_in(card: UpgradeCard, index: int) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(index * 0.08)
	tw.tween_property(card, "scale", Vector2.ONE, 0.3)


func load_upgrades (current_wave : int) -> void:
	for child in items_container.get_children():
		child.queue_free()
		
	var config := Global.UPGRADE_PROBABILITY_CONFIG
	var selected_upgrades := Global.select_items_for_offer(upgrade_list, current_wave, config, Global.upgrade_pity_counters)
	
	for i in selected_upgrades.size():
		var card_instance := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
		items_container.add_child(card_instance)
		card_instance.item_data = selected_upgrades[i]
		card_instance.scale = Vector2.ZERO
		_animate_card_in(card_instance, i)
