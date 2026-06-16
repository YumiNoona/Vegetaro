extends Button
class_name ItemCard

signal on_item_card_selected(card: ItemCard)

@export var item: ItemBase: set = _set_item

@onready var item_icon: TextureRect = $ItemIcon

func _ready() -> void:
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_hover_end)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _set_item(value: ItemBase) -> void:
	item = value
	item_icon.texture = item.item_icon

	var style := Global.get_tier_style(item.item_tier)
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", Global.get_tier_hover_style(item.item_tier))
	add_theme_stylebox_override("pressed", Global.get_tier_pressed_style(item.item_tier))

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

func _on_hover() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25)

func _on_hover_end() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func _on_press() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)

func _on_release() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
