extends PanelContainer

var paused: bool = false


func _ready() -> void:
	# Bouton "Menu principal" ajoute par code, insere avant "Quitter".
	var btn := Button.new()
	btn.text = "MENU PRINCIPAL"
	$VBoxContainer.add_child(btn)
	$VBoxContainer.move_child(btn, $VBoxContainer.get_child_count() - 2)
	btn.pressed.connect(_on_menu_button_pressed)


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


func _on_menu_button_pressed() -> void:
	Transitions.change_scene("res://scenes/ui/main_menu.tscn")
