extends ItemBase
class_name ItemWeapon

enum WeaponType {
	MELEE,
	RANGE
}

@export var type: WeaponType
@export var scene: PackedScene
@export var stats: WeaponStats
@export var upgrade_to: ItemWeapon

func get_description() -> String:
	return "[code]Damage: [color=green]%s[/color]\nCooldown: [color=green]%s[/color]\nRange: [color=green]%s[/color]\nCritical: [color=green]%s%%[/color][/code]" % [stats.damage, stats.cooldown, stats.max_range, stats.crit_chance * 100]   
	
