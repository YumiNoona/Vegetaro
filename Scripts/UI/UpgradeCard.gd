extends Panel
class_name UpgradeCard


@onready var item_icon: TextureRect = %Icon
@onready var item_name: Label = %Name
@onready var item_description: Label = %Description

@export var item_data : ItemUpgrade: set = _set_data


func _set_data(value: ItemUpgrade) -> void:
	item_data = value
	item_icon.texture = item_data.item_icon
	item_name.text = item_data.item_name
	item_description.text = item_data.description

	var style:= Global.get_tier_style(item_data.item_tier)
	add_theme_stylebox_override("panel", style)

func _on_custom_button_pressed() -> void:
	if item_data and is_instance_valid(Global.player):
		item_data.apply_upgrade()
		SoundManager.play_sound(SoundManager.Sound.UI)
		Global.on_upgrade_selected.emit()
