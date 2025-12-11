extends ItemBase
class_name ItemPassive

@export_category("Stat Modification")
## The amount to add to the selected stat (see Add Stats).
@export var add_value: float = 0.0
## The stat to increase when this passive is applied.
@export_enum("health", "damage", "speed", "cooldown", "hp_regen", "armor", "crit_chance", "attack_speed", "life_steal", "luck", "harvesting") var add_stats: String
## The amount to remove from the selected stat (see Remove Stats).
@export var remove_value: float = 0.0
## The stat to decrease when this passive is applied.
@export_enum("health", "damage", "speed", "cooldown", "hp_regen", "armor", "crit_chance", "attack_speed", "life_steal", "luck", "harvesting") var remove_stats: String

@export_category("Dash Effects")
## Amount healed when dashing.
@export var heal_on_dash: float = 0.0
## Coins gained when dashing.
@export var coins_on_dash: int = 0

@export_category("Coin & Life Effects")
## Double coins gained from enemies.
@export var double_coins: bool = false
## Revive once upon death.
@export var extra_life: bool = false

@export_category("Reflect Effects")
## Percentage of damage reflected to attacker (e.g., 0.2 for 20%).
@export var reflect_percent: float = 0.0

@export_category("On Kill Effects")
## Speed gained after killing an enemy.
@export var speed_on_kill: float = 0.0
## Duration of speed boost after kill (in seconds).
@export var speed_on_kill_duration: float = 2.0

@export_category("Cooldown Effects")
## Percentage reduction to cooldowns (e.g., 0.2 for 20%).
@export var cooldown_reduction: float = 0.0

@export_category("Special Passives")
## Enable Momentum passive.
@export var momentum: bool = false
## Enable Glass Cannon passive.
@export var glass_cannon: bool = false
## Enable Static Field passive.
@export var static_field: bool = false
## Enable Retaliation passive.
@export var retaliation: bool = false
## Enable Unstoppable passive.
@export var unstoppable: bool = false

var used_extra_life := false

func get_description() -> String:
	var description_parts: Array[String] = []
	
	# Special passives - return predefined descriptions
	if momentum:
		return "[code]Gain [color=green]+10 Speed[/color] per enemy kill. Stacks up to [color=green]5 times[/color] for [color=green]3 seconds[/color].[/code]"
	if glass_cannon:
		return "[code][color=green]+100% Damage[/color]\n[color=red]-50% Health[/color][/code]"
	if static_field:
		return "[code]Deal [color=green]20 damage[/color] to all enemies within [color=green]200 units[/color] every [color=green]5 seconds[/color].[/code]"
	if retaliation:
		return "[code]Gain [color=green]+20% Damage[/color] for [color=green]5 seconds[/color] after taking damage.[/code]"
	if unstoppable:
		return "[code]Become immune to crowd control when moving at maximum speed for [color=green]2 seconds[/color].[/code]"
	
	# Helper function to format stat names
	var format_stat_name = func(stat: String) -> String:
		var stat_map = {
			"health": "Health",
			"damage": "Damage",
			"speed": "Speed",
			"cooldown": "Cooldown",
			"hp_regen": "HP Regen",
			"armor": "Armor",
			"crit_chance": "Crit Chance",
			"attack_speed": "Attack Speed",
			"life_steal": "Life Steal",
			"luck": "Luck",
			"harvesting": "Harvesting",
			"block_chance": "Block Chance"
		}
		return stat_map.get(stat, stat.capitalize().replace("_", " "))
	
	# Stat modifications
	if add_value != 0.0 and add_stats != "":
		var stat_name = format_stat_name.call(add_stats)
		var value_str = str(add_value)
		# Format percentage stats
		if add_stats in ["crit_chance", "life_steal", "block_chance"]:
			value_str = str(add_value * 100) + "%"
		description_parts.append("[color=green]+%s %s[/color]" % [value_str, stat_name])
	
	if remove_value != 0.0 and remove_stats != "":
		var stat_name = format_stat_name.call(remove_stats)
		var value_str = str(remove_value)
		# Format percentage stats
		if remove_stats in ["crit_chance", "life_steal", "block_chance"]:
			value_str = str(remove_value * 100) + "%"
		description_parts.append("[color=red]-%s %s[/color]" % [value_str, stat_name])
	
	# Dash effects
	if heal_on_dash > 0.0:
		description_parts.append("Heal [color=green]%s HP[/color] when dashing" % str(heal_on_dash))
	if coins_on_dash > 0:
		description_parts.append("Gain [color=green]%s coins[/color] when dashing" % str(coins_on_dash))
	
	# Coin & Life effects
	if double_coins:
		description_parts.append("[color=green]Double[/color] coins from enemies")
	if extra_life:
		description_parts.append("[color=green]Revive once[/color] upon death")
	
	# Reflect effects
	if reflect_percent > 0.0:
		var reflect_percent_display = reflect_percent * 100
		description_parts.append("Reflect [color=green]%s%%[/color] of damage taken back to attacker" % str(reflect_percent_display))
	
	# On Kill effects
	if speed_on_kill > 0.0:
		description_parts.append("Gain [color=green]+%s Speed[/color] for [color=green]%s seconds[/color] after killing an enemy" % [str(speed_on_kill), str(speed_on_kill_duration)])
	
	# Cooldown effects
	if cooldown_reduction > 0.0:
		var cooldown_percent = cooldown_reduction * 100
		description_parts.append("[color=green]-%s%%[/color] cooldown reduction" % str(cooldown_percent))
	
	# Build final description
	if description_parts.is_empty():
		return "[code]No description available[/code]"
	
	return "[code]%s[/code]" % "\n".join(description_parts)

func apply_passive() -> void:
	# Valid UnitStats properties that can be modified
	var valid_stats = ["health", "damage", "speed", "cooldown", "hp_regen", "armor", "crit_chance", "attack_speed", "life_steal", "luck", "harvesting"]
	
	if add_value != 0 and add_stats != "":
		# Trim whitespace and validate
		add_stats = add_stats.strip_edges()
		if add_stats in valid_stats:
			Global.player.stats[add_stats] += add_value
		else:
			push_error("Invalid stat '%s' in ItemPassive '%s'. Valid stats: %s" % [add_stats, item_name, ", ".join(valid_stats)])
	if remove_value != 0 and remove_stats != "":
		# Trim whitespace and validate
		remove_stats = remove_stats.strip_edges()
		if remove_stats in valid_stats:
			Global.player.stats[remove_stats] -= remove_value
		else:
			push_error("Invalid stat '%s' in ItemPassive '%s'. Valid stats: %s" % [remove_stats, item_name, ", ".join(valid_stats)])
	if heal_on_dash > 0.0:
		if not Global.player.is_connected("on_dash", Callable(self, "_on_player_dash")):
			Global.player.connect("on_dash", Callable(self, "_on_player_dash"))
	if double_coins:
		if not Global.is_connected("on_enemy_died", Callable(self, "_on_enemy_died")):
			Global.connect("on_enemy_died", Callable(self, "_on_enemy_died"))
	if extra_life:
		if not Global.player.health_component.on_unit_died.is_connected(_on_player_died):
			Global.player.health_component.on_unit_died.connect(_on_player_died)
	if reflect_percent > 0.0:
		if not Global.player.health_component.on_unit_hit.is_connected(_on_player_hit):
			Global.player.health_component.on_unit_hit.connect(_on_player_hit)
	if speed_on_kill > 0.0:
		if not Global.is_connected("on_enemy_died", Callable(self, "_on_enemy_killed")):
			Global.connect("on_enemy_died", Callable(self, "_on_enemy_killed"))
	if coins_on_dash > 0:
		if not Global.player.is_connected("on_dash", Callable(self, "_on_dash_coins")):
			Global.player.connect("on_dash", Callable(self, "_on_dash_coins"))
	if cooldown_reduction > 0.0:
		Global.player.stats.cooldown *= (1.0 - cooldown_reduction)
	# Special passives
	if momentum:
		Global.player.enable_momentum()
	if glass_cannon:
		Global.player.enable_glass_cannon()
	if static_field:
		Global.player.enable_static_field()
	if retaliation:
		Global.player.enable_retaliation()
	if unstoppable:
		Global.player.enable_unstoppable()

func _on_enemy_died(enemy):
	Global.coins += enemy.stats.gold_drop # Add extra coins

func _on_player_dash():
	Global.player.health_component.heal(heal_on_dash)

func _on_player_died():
	if not used_extra_life:
		used_extra_life = true
		Global.player.health_component.current_health = Global.player.stats.health
		Global.player.health_component.on_health_changed.emit(Global.player.stats.health, Global.player.stats.health)

func _on_player_hit(hitbox: HitboxComponent):
	if hitbox and hitbox.source and hitbox.source.has_method("health_component"):
		var attacker = hitbox.source
		var reflect_damage = hitbox.damage * reflect_percent
		if attacker.has_node("HealthComponent"):
			attacker.get_node("HealthComponent").take_damage(reflect_damage)

func _on_enemy_killed(_enemy):
	Global.player.stats.speed += int(speed_on_kill)
	await Global.player.get_tree().create_timer(speed_on_kill_duration).timeout
	Global.player.stats.speed -= int(speed_on_kill)

func _on_dash_coins():
	Global.coins += coins_on_dash
