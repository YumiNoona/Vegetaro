extends Node2D
class_name WeaponBehavior

@export var weapon: Weapon

var critical := false

func execute_attack() -> void:
	pass

func get_damage() -> float:
	var base := weapon.data.stats.damage
	var damage := base

	if weapon.data.type == ItemWeapon.WeaponType.RANGE:
		var player_multi := 1.0 + (Global.player.stats.damage * 0.06)
		player_multi = clamp(player_multi, 1.0, 2.5)

		var current_wave := 1
		var arena := get_tree().get_first_node_in_group("arena")
		if arena and arena.has_node("Spawner"):
			var spawner = arena.get_node("Spawner")
			if spawner:
				current_wave = spawner.wave_index

		var wave_multi: float = 1.0 + max(0, current_wave - 1) * 0.02
		wave_multi = min(wave_multi, 2.0)

		damage = base * player_multi * wave_multi
	else:
		damage = base + Global.player.stats.damage

	var crit_chance := weapon.data.stats.crit_chance
	if Global.get_chance_sucess(crit_chance):
		critical = true
		damage = ceil(damage * weapon.data.stats.crit_damage)
	return damage


func apply_life_steal() -> void:
	var steal_chance := (Global.player.stats.life_steal / 100.0) + weapon.data.stats.life_steal
	var can_steal := Global.get_chance_sucess(steal_chance)
	if can_steal and is_instance_valid(Global.player):
		Global.player.health_component.heal(1.0)
		Global.on_create_heal_text.emit(Global.player, 1.0)
