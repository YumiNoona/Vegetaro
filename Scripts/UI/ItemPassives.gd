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

func apply_passive() -> void:
	if add_value != 0:
		Global.player.stats[add_stats] += add_value
	if remove_value != 0:
		Global.player.stats[remove_stats] -= remove_value
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
		print("Revived with extra life!")

func _on_player_hit(hitbox: HitboxComponent):
	if hitbox and hitbox.source and hitbox.source.has_method("health_component"):
		var attacker = hitbox.source
		var reflect_damage = hitbox.damage * reflect_percent
		if attacker.has_node("HealthComponent"):
			attacker.get_node("HealthComponent").take_damage(reflect_damage)
			print("Reflected ", reflect_damage, " damage to attacker!")

func _on_enemy_killed(_enemy):
	Global.player.stats.speed += speed_on_kill
	await Global.player.get_tree().create_timer(speed_on_kill_duration).timeout
	Global.player.stats.speed -= speed_on_kill

func _on_dash_coins():
	Global.coins += coins_on_dash
