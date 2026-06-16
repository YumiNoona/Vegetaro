extends Node

@warning_ignore("UNUSED_SIGNAL")
signal on_create_block_text(unit: Node2D)

@warning_ignore("UNUSED_SIGNAL")
signal on_create_damage_text(unit: Node2D, hitbox: HitboxComponent)

@warning_ignore("UNUSED_SIGNAL")
signal on_create_heal_text(unit: Node2D, heal: float)

@warning_ignore("UNUSED_SIGNAL")
signal on_upgrade_selected

@warning_ignore("UNUSED_SIGNAL")
signal on_enemy_died(enemy: Enemy)

@warning_ignore("UNUSED_SIGNAL")
signal on_player_died

var admob = null



const M_FLASH = preload("res://Shaders/M_Flash.tres")
const FLOATING_TEXT_SCENE = preload("res://Scenes/UI/Core/FloatingText.tscn")
const COINS_SCENE = preload("res://Scenes/UI/Coins/Coins.tscn")
const ITEM_CARD_SCENE = preload("res://Scenes/UI/Card/ItemCard.tscn")
const SELECTION_CARD_SCENE = preload("res://Scenes/UI/Selection/SelectionCard.tscn")
const ENEMY_SPAWN_EFFECT_SCENE = preload("res://Scenes/Effects/EnemySpawnEffect.tscn")
const GAME_OVER_SCENE = preload("res://Scenes/UI/Menu/GameOverPanel.tscn")


const COMMON_STYLE = preload("res://Scenes/UI/Styles/CommonStyle.tres")
const EPIC_STYLE = preload("res://Scenes/UI/Styles/EpicStyle.tres")
const LEGENDARY_STYLE = preload("res://Scenes/UI/Styles/LegendaryStyle.tres")
const RARE_STYLE = preload("res://Scenes/UI/Styles/RareStyle.tres")



const UPGRADE_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 2, "base_multi": 0.06 },
	"epic": { "start_wave": 4, "base_multi": 0.02 },
	"legendary": { "start_wave": 7, "base_multi": 0.0023 },
}

const UPGRADE_PITY_CONFIG = {
	"rare": { "pity_waves": 3, "min_tier": 1 },
	"epic": { "pity_waves": 5, "min_tier": 2 },
	"legendary": { "pity_waves": 10, "min_tier": 3 },
}

const SHOP_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 2, "base_multi": 0.10 },
	"epic": { "start_wave": 4, "base_multi": 0.06 },
	"legendary": { "start_wave": 7, "base_multi": 0.01 },
}

const SHOP_PITY_CONFIG = {
	"rare": { "pity_waves": 4, "min_tier": 1 },
	"epic": { "pity_waves": 7, "min_tier": 2 },
	"legendary": { "pity_waves": 12, "min_tier": 3 },
}


const TIER_COLORS: Dictionary[UpgradeTier, Color] = {
	UpgradeTier.RARE: Color(0.0, 0.557, 0.741),
	UpgradeTier.EPIC: Color(0.478, 0.251, 0.71),
	UpgradeTier.LEGENDARY: Color(0.906, 0.212, 0.212),
}

var available_players: Dictionary[String, PackedScene] = {
	"Brawler":preload("res://Scenes/Player/PlayerBrawler.tscn"),
	"Bunny":preload("res://Scenes/Player/PlayerBunny.tscn"),
	"Crazy":preload("res://Scenes/Player/PlayerCrazy.tscn"),
	"Ghost":preload("res://Scenes/Player/PlayerGhost.tscn"),
	"GhostCry":preload("res://Scenes/Player/PlayerGhostCry.tscn"),
	"Knight":preload("res://Scenes/Player/PlayerKnight.tscn"),
	"WellRounded":preload("res://Scenes/Player/PlayerWellRounded.tscn")
} 


enum UpgradeTier{
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var coins: int = 100
var player: Player
var game_paused := false

var main_player_selected : UnitStats
var main_weapon_selected : ItemWeapon

var equipped_weapons: Array[ItemWeapon]

# Gacha pity counters: [waves_since_rare, waves_since_epic, waves_since_legendary]
var upgrade_pity_counters: Array[int] = [0, 0, 0]
var shop_pity_counters: Array[int] = [0, 0, 0]

# Audio settings
var music_enabled := true
var sfx_enabled := true
const SETTINGS_FILE = "user://settings.save"



func show_rewarded_ad(on_rewarded_callable: Callable) -> void:
	if admob and admob.is_rewarded_loaded():
		admob.show_rewarded()
		admob.connect("on_rewarded", on_rewarded_callable, CONNECT_ONE_SHOT)



func get_harvesting_coins() -> void:
	if not player:
		return
	coins += int(player.stats.harvesting)

func get_selected_player() -> Player:
	if not main_player_selected:
		push_error("No player selected") 
		return null
	var player_scene := available_players[main_player_selected.name]
	if not player_scene:
		push_error("Player scene not found") 
		return null
	var player_instance := player_scene.instantiate() as Player
	player = player_instance
	return player_instance


func get_chance_sucess(chance: float) -> bool:
	var random := randf_range(0, 1.0)
	if random < chance:
		return true
	return false

func get_tier_style(tier: UpgradeTier) -> StyleBoxFlat:
	match tier:
		UpgradeTier.COMMON:
			return COMMON_STYLE
		UpgradeTier.RARE:
			return RARE_STYLE
		UpgradeTier.EPIC:
			return EPIC_STYLE
		_:
			return LEGENDARY_STYLE

func calculate_tier_probability(current_wave: int, config: Dictionary) -> Array[float]:
	var common_chance := 0.0
	var rare_chance := 0.0
	var epic_chance := 0.0
	var legendary_chance := 0.0
	
	# RARE: Starts increasing from wave 2 (0% at wave 1)
	if current_wave >= config.rare.start_wave:
		rare_chance = min(1.0, (current_wave - 1) * config.rare.base_multi)
	
	# EPIC: Starts increasing from wave 4 (0% at wave 3)
	if current_wave >= config.epic.start_wave:
		epic_chance = min(1.0, (current_wave - 3) * config.epic.base_multi)
	
	# LEGENDARY: Starts increasing from wave 7 (0% at wave 6)
	if current_wave >= config.legendary.start_wave:
		legendary_chance = min(1.0, (current_wave - 6) * config.legendary.base_multi)
	
	# Player luck increases the chance of finding higher tiers.
	# Example: 10 luck = 10% chance = 1.1 multi
	#var luck_factor := 1.0 + (Global.player.stats.luck / 100.0)
	var luck_factor := 1.0 + (1 / 100.0)
	rare_chance *= luck_factor
	epic_chance *= luck_factor
	legendary_chance *= luck_factor
	
	# Normalize probabilities
	var total_non_common_chances := rare_chance + epic_chance + legendary_chance
	if total_non_common_chances > 1.0:
		var scale_down := 1.0 / total_non_common_chances
		rare_chance *= scale_down
		epic_chance *= scale_down
		legendary_chance *= scale_down
		total_non_common_chances = 1.0
	
	# Common takes the remaining probability
	common_chance = 1.0 - total_non_common_chances
	
	# Debug print
	#print("Wave: %d, Luck: %.1f => Chances: C:%.2f R:%.2f E:%.2f L:%.2f" % 
	#[current_wave, Global.player.stats.luck, common_chance, rare_chance, epic_chance, legendary_chance])
	
	return [
		max(0.0, common_chance),
		max(0.0, rare_chance),
		max(0.0, epic_chance),
		max(0.0, legendary_chance),
	]


func select_items_for_offer(item_pool: Array, current_wave: int, config: Dictionary, pity_counters: Array[int] = []) -> Array:
	
	var tier_chances := calculate_tier_probability(current_wave, config)
	
	# Determine which pity config to use
	var pity_config: Dictionary
	if pity_counters == upgrade_pity_counters:
		pity_config = UPGRADE_PITY_CONFIG
	elif pity_counters == shop_pity_counters:
		pity_config = SHOP_PITY_CONFIG
	
	# Check pity thresholds: force minimum tier if pity is met
	var forced_min_tier := 0  # 0 = Common (no force)
	if pity_config and not pity_counters.is_empty():
		for tier_key in ["legendary", "epic", "rare"]:
			var tier_idx := 3 if tier_key == "legendary" else (2 if tier_key == "epic" else 1)
			var tier_pity = pity_config[tier_key]
			if current_wave >= tier_pity.pity_waves and pity_counters[tier_idx - 1] >= tier_pity.pity_waves:
				forced_min_tier = max(forced_min_tier, tier_pity.min_tier)
	
	var legendary_limit = tier_chances[3]
	var epic_limit = legendary_limit + tier_chances[2]
	var rare_limit = epic_limit + tier_chances[1]
	
	var offered_items: Array = []
	var max_attempts = 100
	var attempts = 0
	var highest_offered_tier := 0
	
	while offered_items.size() < 4 and attempts < max_attempts:
		attempts += 1
		var roll := randf()
		var chosen_tier_index := 0
		if roll < legendary_limit:
			chosen_tier_index = 3
		elif roll < epic_limit:
			chosen_tier_index = 2
		elif roll < rare_limit:
			chosen_tier_index = 1
		
		# Override tier if pity forces a minimum
		if chosen_tier_index < forced_min_tier:
			chosen_tier_index = forced_min_tier
		
		var potential_items: Array = []
		var current_search_tier_index := chosen_tier_index
		
		while potential_items.is_empty() and current_search_tier_index >= 0:
			potential_items = item_pool.filter(func(item: ItemBase): return item.item_tier == current_search_tier_index)
			
			if potential_items.is_empty():
				current_search_tier_index -= 1
			else:
				break
		
		if not potential_items.is_empty():
			var selected_item = potential_items.pick_random()
			
			if not offered_items.has(selected_item):
				offered_items.append(selected_item)
				if selected_item.item_tier > highest_offered_tier:
					highest_offered_tier = selected_item.item_tier
	
	# Update pity counters based on highest tier offered
	if pity_counters and not pity_counters.is_empty():
		# Rare (tier 1)
		if highest_offered_tier >= 1:
			pity_counters[0] = 0
		else:
			pity_counters[0] += 1
		# Epic (tier 2)
		if highest_offered_tier >= 2:
			pity_counters[1] = 0
		else:
			pity_counters[1] += 1
		# Legendary (tier 3)
		if highest_offered_tier >= 3:
			pity_counters[2] = 0
		else:
			pity_counters[2] += 1
	
	return offered_items


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index >= 0:
		AudioServer.set_bus_mute(music_bus_index, not enabled)
	save_audio_settings()


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index >= 0:
		AudioServer.set_bus_mute(sfx_bus_index, not enabled)
	save_audio_settings()


func save_audio_settings() -> void:
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_var(music_enabled)
		file.store_var(sfx_enabled)
		file.close()


func load_audio_settings() -> void:
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file:
		music_enabled = file.get_var()
		sfx_enabled = file.get_var()
		file.close()
	
	# Apply loaded settings
	set_music_enabled(music_enabled)
	set_sfx_enabled(sfx_enabled)
