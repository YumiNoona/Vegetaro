extends Node

enum Sound{
	ENEMY_HIT,
	FIRE,
	UI
}

var sound_dictionary : Dictionary [Sound, Resource] = {
	Sound.ENEMY_HIT: preload("res://Assets/Audio/EnemyHit.wav"),
	Sound.FIRE: preload("res://Assets/Audio/ShotgunFire.wav"),
	Sound.UI: preload("res://Assets/Audio/UI Pop.mp3"),
}

@export var stream_players: Array[AudioStreamPlayer]

func play_sound(type: int) -> void:
	# Check if SFX is enabled
	if not Global.sfx_enabled:
		return
		
	var stream := get_free_stream_player()
	if not stream:
		return
		
	var audio := sound_dictionary[type]
	stream.stream = audio
	stream.pitch_scale = randf_range(0.8,1.3)
	stream.play()



func get_free_stream_player() -> AudioStreamPlayer:
	for stream: AudioStreamPlayer in stream_players:
		if not stream.playing:
			return stream
			
	return null
