extends Panel

func _on_btn_restart_pressed() -> void:
	get_tree().paused = false
	# Reset any global state here
	Global.player = null
	Global.main_player_selected = null
	Global.main_weapon_selected = null
	get_tree().reload_current_scene()


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
