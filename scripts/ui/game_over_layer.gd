extends CanvasLayer
## Ecran de fin de partie (construit par code). Affiche le bilan, signale les
## records et permet de relancer ou de quitter. Corrige l'ancien cul-de-sac ou
## la mort du joueur laissait la partie figee sans aucune issue.

const ACCENT := Color(1, 0.85, 0.3)


func setup(stats: Dictionary) -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)

	_add_label(vb, "GAME OVER", 84, Color(0.9, 0.25, 0.25), 8)

	if stats.get("new_high_score", false):
		_add_label(vb, "NOUVEAU MEILLEUR SCORE !", 30, ACCENT, 4)
	elif stats.get("new_best_wave", false):
		_add_label(vb, "NOUVELLE MEILLEURE VAGUE !", 30, ACCENT, 4)

	_add_label(vb, "Vague atteinte : %d" % stats.get("wave", 0), 32, Color.WHITE, 3)
	_add_label(vb, "Score : %d" % stats.get("score", 0), 28, Color.WHITE, 3)
	_add_label(vb, "Ennemis tues : %d" % stats.get("kills", 0), 28, Color.WHITE, 3)
	_add_label(vb, "Meilleur score : %d   |   Meilleure vague : %d" % [
		stats.get("high_score", 0), stats.get("best_wave", 0)], 20, Color(0.7, 0.7, 0.75), 2)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vb.add_child(spacer)

	var restart := _make_button("REJOUER")
	restart.pressed.connect(_on_restart)
	vb.add_child(restart)

	var menu := _make_button("MENU PRINCIPAL")
	menu.pressed.connect(func(): Transitions.change_scene("res://scenes/ui/main_menu.tscn"))
	vb.add_child(menu)

	var quit := _make_button("QUITTER")
	quit.pressed.connect(func(): get_tree().quit())
	vb.add_child(quit)

	restart.grab_focus()

	bg.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bg, "modulate:a", 1.0, 0.4)


func _add_label(parent: Node, text: String, size: int, color: Color, outline: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", outline)
	parent.add_child(lbl)


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 56)
	b.add_theme_font_size_override("font_size", 28)
	return b


func _on_restart() -> void:
	Transitions.reload_scene()
