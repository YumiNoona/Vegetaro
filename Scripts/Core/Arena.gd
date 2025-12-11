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
@onready var joystick: VirtualJoystick = %JoyStick
@onready var selection_panel = %SelectionPanel
@onready var game_over_panel = %GameOverPanel
@onready var bg_player: AudioStreamPlayer = $BGPlayer


var gold_list: Array[Coins]
var game_started := false  # Track if game has actually started (player was created)


func _process(_delta: float) -> void:
	# Check if player is dead and show game over if needed (backup check)
	# Only check if game has started (player was created) and player is now dead
	if game_started and not Global.player and not game_over_panel.visible:
		# Player died but game over panel not shown yet - show it now
		show_game_over()
		return
	
	if Global.game_paused: 
		_update_joystick_visibility()
		return
	wave_index_label.text = spawner.get_wave_text()
	wave_time_label.text = spawner.get_wave_timer_text()
	_update_joystick_visibility()



func _ready() -> void:
	add_to_group("arena")
	Global.on_create_block_text.connect(_on_create_block_text)
	Global.on_create_damage_text.connect(_on_create_damage_text)
	Global.on_upgrade_selected.connect(on_upgrade_selected)
	Global.on_create_heal_text.connect(on_create_heal_text)
	Global.on_enemy_died.connect(_on_enemy_died)
	Global.on_player_died.connect(_on_player_died)
	
	# Control background music based on settings
	if bg_player:
		bg_player.bus = "Music"
		if not Global.music_enabled:
			bg_player.stop()
		elif not bg_player.playing:
			bg_player.play()
	
	# Initially hide joystick (will show when gameplay starts)
	_update_joystick_visibility()
	
	# Initially hide game over panel
	if game_over_panel:
		game_over_panel.visible = false

func _update_joystick_visibility() -> void:
	if not joystick:
		return
	

	var selection_visible = selection_panel.visible if selection_panel else false
	var game_over_visible = game_over_panel.visible if game_over_panel else false
	var should_show = not Global.game_paused \
		and not upgrade_panel.visible \
		and not shop_panel.visible \
		and not selection_visible \
		and not game_over_visible \
		and Global.player != null
	
	# Only show joystick on mobile devices (or if force_visible is set for testing)
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS")
	joystick.visible = should_show and (joystick.force_visible or is_mobile)



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
	gold_instance.value = int(enemy.stats.gold_drop)
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
	_update_joystick_visibility()


func start_new_wave() -> void:
	Global.game_paused = false
	spawner.wave_index += 1
	spawner.start_wave()
	Global.player.update_player_new_wave()



func on_upgrade_selected () -> void:
	upgrade_panel.hide()
	shop_panel.load_shop(spawner.wave_index)
	shop_panel.show()
	_update_joystick_visibility()



func _on_spawner_on_wave_completed() -> void:
	if not Global.player: return
	clean_arena()
	await get_tree().create_timer(1.0).timeout
	show_upgrades()
	clean_arena()

func _on_shop_panel_on_shop_next_wave() -> void:
	shop_panel.hide()
	start_new_wave()
	_update_joystick_visibility()

func _on_enemy_died(enemy: Enemy) -> void:
	spawn_coins(enemy)

func _on_player_died() -> void:
	show_game_over()

func show_game_over() -> void:
	if not game_over_panel:
		return
		
	# Only show if game has actually started (player was created)
	if not game_started:
		return
		
	# Prevent multiple calls
	if game_over_panel.visible:
		return
		
	# Stop all timers immediately
	spawner.spawn_timer.stop()
	spawner.wave_timer.stop()
	
	# Pause the game first
	Global.game_paused = true
	get_tree().paused = true
	
	# Show panel and bring to front
	game_over_panel.visible = true
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Move to front of GameUI to ensure it's on top
	var game_ui = game_over_panel.get_parent()
	if game_ui:
		game_ui.move_child(game_over_panel, game_ui.get_child_count() - 1)
	
	_update_joystick_visibility()


func _on_selection_panel_on_selection_completed() -> void:
	var player := Global.get_selected_player()
	add_child(player)
	player.add_weapon(Global.main_weapon_selected)
	shop_panel.create_item_weapon(Global.main_weapon_selected)
	Global.equipped_weapons.append(Global.main_weapon_selected)
	
	# Mark game as started
	game_started = true
	
	# Connect joystick to player if available
	if joystick and player:
		player.joystick = joystick
	
	spawner.start_wave()
	Global.game_paused = false
	_update_joystick_visibility()
