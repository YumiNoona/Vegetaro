extends Node2D
class_name Arena

@export var normal_color: Color
@export var blocked_color: Color
@export var critical_color: Color
@export var hp_color: Color

@onready var wave_index_label: Label = %WaveIndexLabel
@onready var wave_time_label: Label = %WaveTimeLabel
@onready var spawner: Spawner = $Spawner
@onready var upgrade_panel: UpgradePanel = %UpgradePanel
@onready var shop_panel: ShopPanel = %ShopPanel
@onready var coins_bag: CoinsBag = %CoinsBag


var gold_list: Array[Coins]


func _process(_delta: float) -> void:
	if Global.game_paused: return
	wave_index_label.text = spawner.get_wave_text()
	wave_time_label.text = spawner.get_wave_timer_text()



func _ready() -> void:
	Global.on_create_block_text.connect(_on_create_block_text)
	Global.on_create_damage_text.connect(_on_create_damage_text)
	Global.on_upgrade_selected.connect(on_upgrade_selected)
	Global.on_create_heal_text.connect(on_create_heal_text)
	Global.on_enemy_died.connect(_on_enemy_died)
	



func clean_arena() -> void:
	if gold_list.size() > 0:
		var target_center_pos := coins_bag.global_position + Vector2(coins_bag.size) / 2.0
		for gold in gold_list:
			if is_instance_valid(gold):
				var gold_item := gold as Coins
				gold_item.set_collection_target(target_center_pos)
	
	gold_list.clear()
	spawner.clear_enemies()


func spawn_coins(enemy: Enemy) -> void:
	var random_angle := randf_range(0, TAU)
	var offset := Vector2.RIGHT.rotated(random_angle) * 35 
	var spawn_pos := enemy.global_position + offset
	
	var gold_instance := Global.COINS_SCENE.instantiate() as Coins
	gold_list.append(gold_instance)
	
	gold_instance.global_position = spawn_pos
	gold_instance.value = enemy.stats.gold_drop
	call_deferred("add_child", gold_instance)



func create_floating_text(unit: Node2D)  -> FLoatingText:
	var instance := Global.FLOATING_TEXT_SCENE.instantiate() as FLoatingText
	get_tree().root.add_child(instance)
	
	var random_angle := randf_range(0.0, TAU)
	var spawn_pos := unit.global_position + Vector2.RIGHT.rotated(random_angle) * 40.0
	
	instance.global_position = spawn_pos
	return instance



func _on_create_block_text(unit: Node2D) -> void:
	var text := create_floating_text(unit)
	text.setup("Blocked!", blocked_color)



func _on_create_damage_text(unit: Node2D, hitbox: HitboxComponent) -> void:
	var text := create_floating_text(unit)
	var color := critical_color if hitbox.critical else normal_color
	text.setup(str(hitbox.damage),color)


func on_create_heal_text(unit: Node2D, heal: float) -> void:
	var text := create_floating_text(unit)
	text.setup("+ %s" % heal, hp_color)



func show_upgrades() -> void:
	upgrade_panel.load_upgrades(spawner.wave_index)
	upgrade_panel.show()


func start_new_wave() -> void:
	Global.game_paused = false
	spawner.wave_index += 1
	spawner.start_wave()
	Global.player.update_player_new_wave()



func on_upgrade_selected () -> void:
	upgrade_panel.hide()
	shop_panel.load_shop(spawner.wave_index)
	shop_panel.show()



func _on_spawner_on_wave_completed() -> void:
	if not Global.player: return
	clean_arena()
	await get_tree().create_timer(1.0).timeout
	show_upgrades()
	clean_arena()

func _on_shop_panel_on_shop_next_wave() -> void:
	shop_panel.hide()
	start_new_wave()

func _on_enemy_died(enemy: Enemy) -> void:
	spawn_coins(enemy)


func _on_selection_panel_on_selection_completed() -> void:
	var player := Global.get_selected_player()
	add_child(player)
	player.add_weapon(Global.main_weapon_selected)
	shop_panel.create_item_weapon(Global.main_weapon_selected)
	Global.equipped_weapons.append(Global.main_weapon_selected)
	
	spawner.start_wave()
	Global.game_paused = false
