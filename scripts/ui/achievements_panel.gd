extends Control
## Panneau listant tous les succes (debloques / verrouilles). Overlay plein ecran.

const ACCENT := Color(1, 0.85, 0.3)


func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	var title := Label.new()
	title.text = "SUCCES  (%d / %d)" % [AchievementManager.unlocked_count(), AchievementManager.DEFS.size()]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)

	for id: String in AchievementManager.DEFS:
		var def: Dictionary = AchievementManager.DEFS[id]
		var unlocked := SaveManager.is_unlocked(id)
		var row := Label.new()
		var mark := "[X]" if unlocked else "[  ]"
		row.text = "%s  %s  -  %s" % [mark, def.title, def.desc]
		row.add_theme_font_size_override("font_size", 22)
		row.add_theme_color_override("font_color", ACCENT if unlocked else Color(0.55, 0.55, 0.6))
		vb.add_child(row)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	vb.add_child(spacer)

	var back := Button.new()
	back.text = "RETOUR"
	back.custom_minimum_size = Vector2(260, 52)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(queue_free)
	vb.add_child(back)
	back.grab_focus()
