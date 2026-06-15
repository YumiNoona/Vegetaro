extends Button
class_name ItemCard

signal on_item_card_selected(card: ItemCard)

@export var item: ItemBase: set = _set_item

@onready var item_icon: TextureRect = $ItemIcon

func _set_item(value: ItemBase) -> void:
	item = value
	item_icon.texture = item.item_icon
	
	var style := Global.get_tier_style(item.item_tier)
	add_theme_stylebox_override("normal", style)


func _on_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.FIRE)
	if item.item_type == ItemBase.ItemType.WEAPON:
		on_item_card_selected.emit(self)

func _get_tooltip(_at_position: Vector2 = Vector2.ZERO) -> String:
	if item:
		if "get_description" in item:
			return item.get_description()
		elif "description" in item:
			return item.description
	return "No item assigned"
