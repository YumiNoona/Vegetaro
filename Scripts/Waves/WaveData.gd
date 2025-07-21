extends Resource
class_name WaveData

enum SpawnType {
	FIXED,
	RANDOM
}

@export var units: Array[WaveUnitData]
@export var from: int
@export var to: int
@export var wave_time:= 20.0
@export var spawn_type := SpawnType.RANDOM

@export var fixed_spawn_time:= 1.0
@export var min_spawn_time:= 1.0
@export var max_spawn_time:= 1.0


#Boss Enemy

@export var is_boss_wave: bool = false
@export var boss_scene: PackedScene
@export var boss_config: Resource # Will be BossConfigResource



func get_random_unit_scene() -> PackedScene:
	if units.is_empty():
		printerr("No Units.")
		return null
		
	var enemies : Array[PackedScene]
	var weight: Array [float]
	
	for unit in units:
		enemies.append(unit.unit_scene)
		weight.append(unit.weight)
		
	var rng := RandomNumberGenerator.new()
	var random_unit = enemies[rng.rand_weighted(weight)]
	return random_unit


func is_valid_index(index: int) -> bool:
	return index >= from and index <= to
