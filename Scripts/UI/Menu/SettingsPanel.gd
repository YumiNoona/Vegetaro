extends Panel

@onready var btn_music: Button = %BTN_Music
@onready var btn_sfx: Button = %BTN_SFX
@onready var btn_back: Button = %BTN_Back

var music_enabled := true
var sfx_enabled := true


func _ready() -> void:
	# Connect button signals
	btn_music.pressed.connect(_on_music_pressed)
	btn_sfx.pressed.connect(_on_sfx_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	
	# Load saved settings
	music_enabled = Global.music_enabled
	sfx_enabled = Global.sfx_enabled
	
	# Update button text
	_update_button_text()


func _update_button_text() -> void:
	btn_music.text = "  MUSIC: " + ("ON" if music_enabled else "OFF") + "  "
	btn_sfx.text = "  SFX: " + ("ON" if sfx_enabled else "OFF") + "  "


func _on_music_pressed() -> void:
	music_enabled = not music_enabled
	Global.set_music_enabled(music_enabled)
	_update_button_text()
	SoundManager.play_sound(SoundManager.Sound.UI)


func _on_sfx_pressed() -> void:
	sfx_enabled = not sfx_enabled
	Global.set_sfx_enabled(sfx_enabled)
	_update_button_text()
	SoundManager.play_sound(SoundManager.Sound.UI)


func _on_back_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	visible = false
