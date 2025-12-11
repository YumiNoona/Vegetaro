extends Panel
class_name UpgradePanel


@onready var items_container: HBoxContainer = %ItemsContainer
const UPGRADE_CARD_SCENE = preload("res://Scenes/UI/Upgrade/UpgradeCard.tscn")

@export var upgrade_list : Array[ItemUpgrade]



func load_upgrades (current_wave : int) -> void:
	for child in items_container.get_children():
		child.queue_free()
		
	var config := Global.UPGRADE_PROBABILITY_CONFIG
	var selected_upgrades := Global.select_items_for_offer(upgrade_list, current_wave, config)
	
	for random_upg: ItemUpgrade in selected_upgrades:
	
		var card_instance := UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
		items_container.add_child(card_instance)
		card_instance.item_data = random_upg
