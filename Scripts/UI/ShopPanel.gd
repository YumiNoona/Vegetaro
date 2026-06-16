extends Panel
class_name ShopPanel

signal on_shop_next_wave

const SHOP_CARD_SCENE = preload("res://Scenes/UI/Shop/ShopCard.tscn")


@export var shop_items: Array[ItemBase]

@onready var items_container: HBoxContainer = %ItemsContainer
@onready var passive_container: GridContainer = %PassiveContainer
@onready var weapons_container: GridContainer = %WeaponsContainer
@onready var btn_combine: Button = %BTN_Combine


const MAX_PASSIVES = 16 # or whatever your item/passive slot limit is
const MAX_WEAPONS = 6   # your weapon slot limit


var context_card : ItemCard
var pending_ad_item: ItemBase = null


func get_passive_count() -> int:
	return passive_container.get_child_count()


func try_purchase_with_ads(item: ItemBase) -> void:
	if Global.coins >= item.item_cost:
		Global.coins -= item.item_cost
		_on_item_purchased(item)
	else:
		pending_ad_item = item
		offer_ad_for_purchase(item)

func offer_ad_for_purchase(item: ItemBase) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Not enough coins! Watch an ad to get this item?"
	dialog.add_button("Watch Ad", true, "watch_ad")
	dialog.add_button("Cancel", false, "cancel")
	dialog.connect("custom_action", Callable(self, "_on_ad_dialog_action").bind(item))
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _on_ad_dialog_action(action: String, item: ItemBase) -> void:
	if action == "watch_ad":
		play_rewarded_ad(item)

func play_rewarded_ad(item: ItemBase) -> void:
	if Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		admob.show_rewarded()
		admob.connect("on_rewarded", Callable(self, "_on_ad_rewarded").bind(item), CONNECT_ONE_SHOT)
	else:
		_on_ad_rewarded("", 0, item)

func _on_ad_rewarded(_currency_type: String, _amount: int, item: ItemBase) -> void:
	var missing_coins = item.item_cost - Global.coins
	Global.coins += missing_coins
	Global.coins -= item.item_cost
	_on_item_purchased(item)
	pending_ad_item = null
	if Engine.has_singleton("GodotAdMob"):
		var admob = Engine.get_singleton("GodotAdMob")
		admob.load_rewarded()

func _ready() -> void:
	for child in passive_container.get_children() : child.queue_free()
	for child in weapons_container.get_children() : child.queue_free()
	_setup_button_hover(get_node("MarginContainer/Control/VBoxContainer/BTN_NewWave"))
	_setup_button_hover(%BTN_Combine)
	_setup_button_hover(get_node("MarginContainer/Control/VBoxContainer/BTN_Sell"))

func _setup_button_hover(btn: Button) -> void:
	if not btn:
		return
	var base = btn.get_theme_stylebox("normal")
	if base and base is StyleBoxFlat:
		btn.add_theme_stylebox_override("hover", Global.make_hover_style(base))
		btn.add_theme_stylebox_override("pressed", Global.make_pressed_style(base))
	btn.mouse_entered.connect(_on_btn_hover.bind(btn))
	btn.mouse_exited.connect(_on_btn_hover_end.bind(btn))
	btn.button_down.connect(_on_btn_press.bind(btn))
	btn.button_up.connect(_on_btn_release.bind(btn))

func _on_btn_hover(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.25)

func _on_btn_hover_end(btn: Button) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.2)

func _on_btn_press(btn: Button) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.1)

func _on_btn_release(btn: Button) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.15)

func _animate_shop_card_in(card: ShopCard, index: int) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(index * 0.08)
	tw.tween_property(card, "scale", Vector2.ONE, 0.3)


func load_shop(current_wave : int) -> void:
	for child in items_container.get_children() : child.queue_free()
	var config := Global.SHOP_PROBABILITY_CONFIG
	var selected_items := Global.select_items_for_offer(shop_items, current_wave, config, Global.shop_pity_counters)
	for i in selected_items.size():
		var card_instance := SHOP_CARD_SCENE.instantiate() as ShopCard
		card_instance.on_item_purchased.connect(_on_item_purchased)
		items_container.add_child(card_instance)
		card_instance.shop_item = selected_items[i]
		card_instance.scale = Vector2.ZERO
		_animate_shop_card_in(card_instance, i)
 

func create_item_card() -> ItemCard:
	var item_card := Global.ITEM_CARD_SCENE.instantiate() as ItemCard
	item_card.on_item_card_selected.connect(_on_item_card_selected)
	return item_card
	
	
func create_item_weapon(weapon: ItemWeapon) -> void:
	var card := create_item_card()
	weapons_container.add_child(card)
	card.item = weapon
	
	

func _on_btn_new_wave_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	on_shop_next_wave.emit()


func _on_item_purchased(item: ItemBase) -> void:
	var item_card := create_item_card()
	
	if item.item_type == ItemBase.ItemType.WEAPON:
		weapons_container.add_child(item_card)
		var weapon := item as ItemWeapon
		Global.player.add_weapon(weapon)
		Global.equipped_weapons.append(weapon)
	
	elif item.item_type == ItemBase.ItemType.PASSIVE:
		passive_container.add_child(item_card)
		var passive := item as ItemPassive
		passive.apply_passive()
	
	item_card.item = item


func _on_item_card_selected(card: ItemCard) -> void:
	context_card = card
	
	var can_merge := false
	if card.item.item_type == ItemBase.ItemType.WEAPON:
		var count := 0
		for weapon: ItemWeapon in Global.equipped_weapons:
			if weapon.item_name == card.item.item_name:
				count += 1
		
		if count >= 2:
			can_merge = true
	
	btn_combine.disabled = not can_merge


func _on_btn_combine_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	if not context_card:
		return
	
	var clicked_weapon := context_card.item as ItemWeapon
	if not clicked_weapon.upgrade_to:
		return
	
	var weapons_to_remove: Array[Weapon] = Global.player.current_weapons.filter(func(w: Weapon): 
		return w.data.item_name == clicked_weapon.item_name).slice(0, 2)
	
	var card_to_remove = weapons_container.get_children().filter(func(c: ItemCard): 
		return c.item.item_name == clicked_weapon.item_name).slice(0, 2)
	
	if weapons_to_remove.size() < 2 or card_to_remove.size() < 2:
		return
	
	# Delete weapons
	for weapon: Weapon in weapons_to_remove:
		Global.player.current_weapons.erase(weapon)
		Global.equipped_weapons.erase(weapon.data)
		weapon.queue_free()
	
	# Delete cards
	for card: ItemCard in card_to_remove:
		card.queue_free()
	
	# Create new Weapon
	var upgraded_weapon: ItemWeapon = load(clicked_weapon.upgrade_to.resource_path)
	Global.player.add_weapon(upgraded_weapon)
	Global.equipped_weapons.append(upgraded_weapon)
	
	# Create new Item Card
	var new_card := create_item_card()
	weapons_container.add_child(new_card)
	new_card.item = upgraded_weapon
	
	context_card = null


func _on_btn_sell_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	if not context_card:
		return
	
	var clicked_weapon := context_card.item as ItemWeapon
	var coins := int(clicked_weapon.item_cost * 0.50)
	
	var weapon_to_remove: Weapon = Global.player.current_weapons.filter(func(w: Weapon): 
		return w.data.item_name == clicked_weapon.item_name).front()
	
	if weapon_to_remove:
		Global.player.current_weapons.erase(weapon_to_remove)
		Global.equipped_weapons.erase(weapon_to_remove.data)
		weapon_to_remove.queue_free()
	
	context_card.queue_free()
	context_card = null
	
	Global.coins += coins
