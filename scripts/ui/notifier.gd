extends CanvasLayer
## Couche de notifications globale (bandeaux de vague + toasts de succes).
## Construite entierement par code, au-dessus de tout le reste.

const ACCENT := Color(1, 0.85, 0.3)
const PANEL_BG := Color(0.12, 0.12, 0.18, 0.92)
const WAVE_STREAM := preload("res://assets/sounds/pumps/bonus_pump.mp3")

var _active_toasts: int = 0
var _wave_sound: AudioStreamPlayer


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wave_sound = AudioStreamPlayer.new()
	_wave_sound.stream = WAVE_STREAM
	add_child(_wave_sound)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.wave_started.connect(_on_wave_started)


func _on_wave_started(w: int) -> void:
	show_banner("VAGUE %d" % w)
	flash(Color(1, 1, 1, 0.45))
	_wave_sound.volume_db = SoundManager.volumes.get("sfx", 0.0)
	_wave_sound.play()


## Flash plein ecran bref (feedback d'impact, ex. nouvelle vague).
func flash(col: Color) -> void:
	var rect := ColorRect.new()
	rect.color = col
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, 0.35)
	tw.tween_callback(rect.queue_free)


func _on_achievement_unlocked(_id: String, title: String, desc: String) -> void:
	show_toast("Succes : " + title, desc)


## Grand bandeau centre (ex. "VAGUE 3").
func show_banner(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_top = -140.0
	lbl.add_theme_font_size_override("font_size", 88)
	lbl.add_theme_color_override("font_color", ACCENT)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 10)
	lbl.modulate.a = 0.0
	lbl.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	lbl.scale = Vector2(0.5, 0.5)
	add_child(lbl)

	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(lbl, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.85)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


## Petit toast en haut a droite (succes, infos).
func show_toast(title: String, desc: String = "") -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	sb.border_color = ACCENT
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)

	var slot := _active_toasts
	_active_toasts += 1
	panel.offset_right = -20.0
	panel.offset_left = -360.0
	panel.offset_top = 20.0 + slot * 78.0

	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", ACCENT)
	vb.add_child(t)
	if desc != "":
		var d := Label.new()
		d.text = desc
		d.add_theme_font_size_override("font_size", 16)
		d.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		vb.add_child(d)

	panel.modulate.a = 0.0
	add_child(panel)

	var start_x := panel.offset_left + 80.0
	panel.offset_left = start_x
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(panel, "offset_left", -360.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.6)
	tw.tween_property(panel, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		panel.queue_free()
		_active_toasts = max(0, _active_toasts - 1)
	)
