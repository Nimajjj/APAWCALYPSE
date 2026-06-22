extends Control
## Ecran d'options autonome (accessible depuis le menu principal). Reprend la
## logique de volume (SoundManager + persistance SaveManager).

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
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)

	var title := Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)

	for g in [["Musique", "music"], ["Effets", "sfx"], ["Interface", "gui"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var lbl := Label.new()
		lbl.text = g[0]
		lbl.custom_minimum_size = Vector2(180, 0)
		lbl.add_theme_font_size_override("font_size", 24)
		row.add_child(lbl)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size = Vector2(320, 0)
		slider.value = SaveManager.get_slider(g[1])
		var gid: String = g[1]
		slider.value_changed.connect(func(v: float) -> void:
			SoundManager.change_volume(gid, SoundManager.slider_to_db(v))
			SaveManager.set_slider(gid, v))
		row.add_child(slider)
		vb.add_child(row)

	var back := Button.new()
	back.text = "RETOUR"
	back.custom_minimum_size = Vector2(260, 50)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(queue_free)
	vb.add_child(back)
	back.grab_focus()
