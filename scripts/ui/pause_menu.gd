extends PanelContainer

var paused: bool = false

func _process(_delta):
	if Input.is_action_just_pressed("esc"):
		if paused:
			unpause()
		else:
			pause()


func pause() -> void:
	visible = true
	get_tree().paused = true
	paused = true


func unpause() -> void:
	visible = false
	get_tree().paused = false
	paused = false
	$"../OptionMenu".visible = false


func _on_resume_button_pressed():
	unpause()


func _on_option_button_pressed():
	$"../OptionMenu".visible = true


func _on_quit_button_pressed():
	get_tree().quit()
