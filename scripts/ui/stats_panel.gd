extends Control
## Statistiques detaillees (cumul de toutes les parties), depuis le menu principal.

const ACCENT := Color(1, 0.85, 0.3)


func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	center.add_child(vb)

	var title := Label.new()
	title.text = "STATISTIQUES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)

	var rows := [
		["Temps de jeu", _fmt_time(SaveManager.total_play_time)],
		["Parties jouees", str(SaveManager.games_played)],
		["Ennemis tues (total)", str(SaveManager.total_kills)],
		["Precision", "%.1f %%" % SaveManager.accuracy_percent()],
		["Meilleur score", str(SaveManager.high_score)],
		["Meilleure vague", str(SaveManager.best_wave)],
		["Argent gagne (cumul)", str(SaveManager.total_money)],
		["Pieces", str(SaveManager.coins)],
	]
	for r in rows:
		var line := Label.new()
		line.text = "%s : %s" % [r[0], r[1]]
		line.add_theme_font_size_override("font_size", 24)
		line.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
		vb.add_child(line)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vb.add_child(spacer)

	var back := Button.new()
	back.text = "RETOUR"
	back.custom_minimum_size = Vector2(260, 50)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(queue_free)
	vb.add_child(back)
	back.grab_focus()


func _fmt_time(seconds: float) -> String:
	var s := int(seconds)
	var h := s / 3600
	var m := (s % 3600) / 60
	var sec := s % 60
	if h > 0:
		return "%dh %02dm %02ds" % [h, m, sec]
	return "%dm %02ds" % [m, sec]
