extends Control
## Menu principal (construit par code). Premier ecran du jeu.

const ACCENT := Color(1, 0.85, 0.3)
const GAME_SCENE := "res://scenes/game/game.tscn"
const MENU_SHADER := preload("res://resources/menu_bg.gdshader")
# Assets UI pixel art (generes via PixelLab). Le fond des boutons texte
# (EmptyCracked en 9-slice) est defini dans le theme projet. Les boutons a
# logo/texte cuit ci-dessous sont utilises tels quels comme TextureButton.
const TITLE_BANNER := preload("res://assets/ui/menu/Title_banner.png")
const BTN_PLAY := preload("res://assets/ui/menu/Play.png")
const BTN_SETTINGS := preload("res://assets/ui/menu/Settings.png")
const BTN_CHALLENGES := preload("res://assets/ui/menu/Challenges.png")
const BTN_UPGRADES := preload("res://assets/ui/menu/Upgrades.png")
const AchievementsPanel := preload("res://scripts/ui/achievements_panel.gd")
const CharacterSelect := preload("res://scripts/ui/character_select.gd")
const OptionsPanel := preload("res://scripts/ui/options_panel.gd")
const StatsPanel := preload("res://scripts/ui/stats_panel.gd")
const ModifiersPanel := preload("res://scripts/ui/modifiers_panel.gd")
const ControlsPanel := preload("res://scripts/ui/controls_panel.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = MENU_SHADER
	bg.material = mat
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)

	# Titre : banniere pixel art en fond + texte (font du jeu) par-dessus.
	var title_holder := Control.new()
	title_holder.custom_minimum_size = Vector2(560, 200)

	var banner := TextureRect.new()
	banner.texture = TITLE_BANNER
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_holder.add_child(banner)

	var title := Label.new()
	title.text = "APAWCALYPSE"
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	title_holder.add_child(title)
	vb.add_child(title_holder)
	# Pulse d'inactivite (juice facon Balatro).
	title_holder.resized.connect(func() -> void: title_holder.pivot_offset = title_holder.size / 2.0)
	var pulse := create_tween().set_loops()
	pulse.tween_property(title_holder, "scale", Vector2(1.05, 1.05), 1.1).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title_holder, "scale", Vector2.ONE, 1.1).set_trans(Tween.TRANS_SINE)

	var sub := Label.new()
	sub.text = "Best score: %d     Best wave: %d     Coins: %d" % [SaveManager.high_score, SaveManager.best_wave, SaveManager.coins]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	vb.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vb.add_child(spacer)

	# Bouton principal : fond vert Play.png en 9-slice + texte (font du jeu).
	var play := _texture_button("Play", BTN_PLAY, _on_play)
	vb.add_child(play)

	# Actions secondaires : texte (font du jeu) sur fond EmptyCracked du theme.
	vb.add_child(_button("Characters", _on_characters))
	vb.add_child(_button("Achievements", _on_achievements))
	vb.add_child(_button("Stats", _on_stats))
	vb.add_child(_button("Controls", _on_controls))
	vb.add_child(_button("Quit", func() -> void: get_tree().quit()))

	# Rangee de boutons-icones : Settings / Challenges / Upgrades.
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.add_theme_constant_override("separation", 18)
	icons.add_child(_image_button(BTN_SETTINGS, _on_options, Vector2(112, 52)))
	icons.add_child(_image_button(BTN_CHALLENGES, _on_modifiers, Vector2(112, 52)))
	icons.add_child(_image_button(BTN_UPGRADES, _on_upgrades, Vector2(112, 52)))
	var icon_spacer := Control.new()
	icon_spacer.custom_minimum_size = Vector2(0, 8)
	vb.add_child(icon_spacer)
	vb.add_child(icons)

	play.grab_focus()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 60)
	# Le fond pixel art (EmptyCracked en 9-slice) vient du theme projet
	# resources/ui_theme.tres, applique a TOUS les boutons du jeu pour la coherence.
	b.pressed.connect(cb)
	UITheme.add_button_juice(b)
	return b


func _image_button(tex: Texture2D, cb: Callable, min_size: Vector2) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.custom_minimum_size = min_size
	b.pressed.connect(cb)
	UITheme.add_button_juice(b)
	return b


## Bouton texte dont le fond est une texture 9-slice (ex: Play.png vert).
func _texture_button(text: String, tex: Texture2D, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 64)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 18
		sb.texture_margin_right = 18
		sb.texture_margin_top = 16
		sb.texture_margin_bottom = 18
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		sb.content_margin_top = 8
		sb.content_margin_bottom = 12
		if state == "hover" or state == "focus":
			sb.modulate_color = Color(1.2, 1.2, 1.15, 1)
		elif state == "pressed":
			sb.modulate_color = Color(0.82, 0.86, 0.82, 1)
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(cb)
	UITheme.add_button_juice(b)
	return b


func _on_play() -> void:
	Transitions.change_scene(GAME_SCENE)


func _on_achievements() -> void:
	var panel := AchievementsPanel.new()
	add_child(panel)
	panel.setup()


func _on_characters() -> void:
	var panel := CharacterSelect.new()
	add_child(panel)
	panel.setup()


func _on_stats() -> void:
	var panel := StatsPanel.new()
	add_child(panel)
	panel.setup()


func _on_options() -> void:
	var panel := OptionsPanel.new()
	add_child(panel)
	panel.setup()


func _on_modifiers() -> void:
	var panel := ModifiersPanel.new()
	add_child(panel)
	panel.setup()


func _on_controls() -> void:
	var panel := ControlsPanel.new()
	add_child(panel)
	panel.setup()


func _on_upgrades() -> void:
	# TODO: brancher l'ecran de meta-progression (upgrades) quand il existera.
	_toast("Upgrades — coming soon")


func _toast(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -120
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", ACCENT)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(label.queue_free)
