extends Control

@onready var btn_start: Button = %BTN_Start
@onready var btn_settings: Button = %BTN_Settings
@onready var btn_credits: Button = %BTN_Credits
@onready var btn_exit: Button = %BTN_Exit

@onready var settings_panel: Control = %SettingsPanel
@onready var credits_panel: Control = %CreditsPanel

const ARENA_SCENE = preload("res://Scenes/Core/Arena.tscn")


func _ready() -> void:
	# Connect button signals
	btn_start.pressed.connect(_on_start_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	# Initially hide panels
	if settings_panel:
		settings_panel.visible = false
	if credits_panel:
		credits_panel.visible = false
	
	# Load audio settings
	Global.load_audio_settings()


func _on_start_pressed() -> void:
	# Play UI sound
	SoundManager.play_sound(SoundManager.Sound.UI)
	# Load Arena scene
	get_tree().change_scene_to_file("res://Scenes/Core/Arena.tscn")


func _on_settings_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	if settings_panel:
		settings_panel.visible = true


func _on_credits_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	if credits_panel:
		credits_panel.visible = true


func _on_exit_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	get_tree().quit()
