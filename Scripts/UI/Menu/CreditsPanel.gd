extends Panel

@onready var btn_back: Button = %BTN_Back


func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	visible = false
