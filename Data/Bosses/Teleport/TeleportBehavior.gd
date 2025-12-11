extends Node

@export var boss: Boss
@export var teleport_cooldown: float = 4.0
@export var teleport_distance: float = 400.0
@export var min_distance_from_edge: float = 100.0  # Minimum distance from arena edges

var arena_rect: Rect2  # Will store the playable area bounds

var in_second_phase := false
var cooldown_timer := 0.0

func _ready():
	if boss:
		boss.second_phase_started.connect(_on_second_phase_started)
		# Get the arena node (assuming it's the boss's grandparent)
		if boss.get_parent() and boss.get_parent().has_method("get_play_area"):
			arena_rect = boss.get_parent().get_play_area()
		else:
			# Fallback to a default area if we can't get the arena
			arena_rect = Rect2(Vector2(0, 0), Vector2(1152, 648))  # Default 16:9 resolution

func _on_second_phase_started():
	in_second_phase = true
	cooldown_timer = teleport_cooldown

func _process(delta):
	if Global.game_paused:
		return

	if in_second_phase:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			_teleport()
			cooldown_timer = teleport_cooldown

func _teleport():
	if not boss:
		return
	
	# Try to find a valid position within bounds
	var max_attempts = 10
	var new_position = Vector2.ZERO
	var valid_position_found = false
	
	for _i in range(max_attempts):
		# Get a random direction and distance
		var angle = randf_range(0, TAU)
		var distance = randf_range(teleport_distance * 0.5, teleport_distance)
		var offset = Vector2.RIGHT.rotated(angle) * distance
		
		# Calculate potential new position
		new_position = boss.global_position + offset
		
		# Check if the new position is within bounds
		if _is_position_in_bounds(new_position):
			valid_position_found = true
			break
	
	# If we found a valid position, teleport there
	if valid_position_found:
		boss.global_position = new_position
		# You can add a teleport effect here if desired

# Check if a position is within the playable area bounds
func _is_position_in_bounds(position: Vector2) -> bool:
	if arena_rect == null:
		return true  # If we don't have arena bounds, allow any position
		
	# Add some padding to keep the boss away from edges
	var padded_rect = Rect2(
		arena_rect.position + Vector2.ONE * min_distance_from_edge,
		arena_rect.size - Vector2.ONE * (min_distance_from_edge * 2)
	)
	
	return padded_rect.has_point(position)
