extends Control
## Ecran de demarrage anime (intro) joue AVANT le menu principal.
## Theme zombie/apocalypse : le titre "APAWCALYPSE" s'assemble lettre par lettre
## (impact + son + tremblement + flash), puis un climax revele le tout avec des
## eclaboussures de sang animees (spritesheet) sur le titre, sur un fond de
## braises/cendres. Skippable par n'importe quelle touche.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MENU_SHADER := preload("res://resources/menu_bg.gdshader")
const SND_RISER := preload("res://assets/sounds/ui/intro_riser.mp3")
const SND_IMPACT := preload("res://assets/sounds/ui/letter_impact.mp3")
const SND_CLIMAX := preload("res://assets/sounds/ui/title_climax.mp3")
const SND_CLAW := preload("res://assets/sounds/ui/claw_scratch.mp3")
const BLOOD_SHEET := preload("res://assets/ui/vfx/blood_sheet.png")
const BLOOD_HFRAMES := 14  # colonnes (frames max par animation)
const BLOOD_VFRAMES := 9   # rangees (= 9 animations differentes)
const CLAW_SHEET := preload("res://assets/ui/vfx/claw_sheet.png")
const CLAW_HFRAMES := 4    # grille 4x2 = 8 frames, 1 animation
const CLAW_VFRAMES := 2
const TITLE := "APAWCALYPSE"
const ACCENT := Color(1, 0.85, 0.3)
const BLOOD := Color(0.55, 0.04, 0.04)
const STEP := 0.16  # cadence d'apparition des lettres

var _letters: Array[Label] = []
var _title_box: HBoxContainer
var _subtitle: Label
var _vfx: Node2D  # calque ou s'affichent les eclaboussures
var _impact_player: AudioStreamPlayer
var _riser_player: AudioStreamPlayer
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Fond braises/cendres (meme shader que le menu, demarre tres sombre).
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = MENU_SHADER
	mat.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)
	mat.set_shader_parameter("spin_speed", 4.0)  # intro un peu plus lente que le menu
	bg.material = mat
	bg.modulate.a = 0.0
	add_child(bg)
	create_tween().tween_property(bg, "modulate:a", 1.0, 1.4)

	add_child(_make_fog())     # brume toxique verte
	add_child(_make_embers())  # braises qui montent

	# Voile rouge plein-ecran pour les flashs d'impact.
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.color = Color(0.7, 0.05, 0.03)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	add_child(flash)

	# Conteneur du titre, centre.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	center.add_child(vb)

	_title_box = HBoxContainer.new()
	_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_box.add_theme_constant_override("separation", 0)
	vb.add_child(_title_box)

	for c in TITLE:
		var l := Label.new()
		l.text = c
		l.add_theme_font_size_override("font_size", 128)
		l.add_theme_color_override("font_color", ACCENT)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 16)
		l.modulate.a = 0.0
		_title_box.add_child(l)
		_letters.append(l)

	_subtitle = Label.new()
	_subtitle.text = "SURVIVE THE PAWPOCALYPSE"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 28)
	_subtitle.add_theme_color_override("font_color", BLOOD)
	_subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	_subtitle.add_theme_constant_override("outline_size", 6)
	_subtitle.modulate.a = 0.0
	vb.add_child(_subtitle)

	# Indice de skip, discret en bas de l'ecran.
	var hint := Label.new()
	hint.text = "Press any key to skip"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -70.0
	hint.offset_bottom = -30.0
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.modulate.a = 0.0
	add_child(hint)
	# Apparait apres un court delai, puis clignote doucement en boucle.
	var ht := create_tween()
	ht.tween_interval(1.0)
	ht.tween_property(hint, "modulate:a", 0.55, 0.5)
	ht.tween_callback(func() -> void:
		var blink := create_tween().set_loops()
		blink.tween_property(hint, "modulate:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)
		blink.tween_property(hint, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE))

	# Calque VFX au-dessus du titre (eclaboussures de sang, griffures...).
	_vfx = Node2D.new()
	add_child(_vfx)

	# Audio.
	_riser_player = AudioStreamPlayer.new()
	_riser_player.stream = SND_RISER
	_riser_player.bus = "Music"
	_riser_player.volume_db = -6.0
	add_child(_riser_player)
	_impact_player = AudioStreamPlayer.new()
	_impact_player.stream = SND_IMPACT
	_impact_player.bus = "SFX"
	add_child(_impact_player)

	_play_intro()


## Sequence principale : riser, impacts lettre par lettre, climax, sous-titre.
func _play_intro() -> void:
	_riser_player.play()

	for i in _letters.size():
		var t := create_tween()
		t.tween_interval(0.9 + i * STEP)
		t.tween_callback(_slam_letter.bind(_letters[i]))

	var climax := 0.9 + _letters.size() * STEP + 0.15
	var seq := create_tween()
	seq.tween_interval(climax)
	seq.tween_callback(_climax)
	seq.tween_interval(0.35)
	seq.tween_callback(_flicker_title)
	seq.tween_property(_subtitle, "modulate:a", 1.0, 0.6)
	seq.tween_interval(1.6)
	seq.tween_callback(_finish)


## Une lettre "tombe" en place : zoom-in + apparition + flash + shake + son.
func _slam_letter(l: Label) -> void:
	if _done:
		return
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(2.4, 2.4)
	l.modulate.a = 1.0
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "scale", Vector2.ONE, 0.22)
	_flash(0.16)
	_shake(6.0, 0.18)
	_impact_player.pitch_scale = randf_range(0.92, 1.12)
	_impact_player.play()


## Climax : gros impact metallique + deux salves de griffures/sang calees sur les
## deux scratchs du son claw_scratch.mp3 (pics analyses a ~0.44s et ~1.40s ;
## on demarre l'anim ~0.1s avant pour que le visuel culmine sur le son).
func _climax() -> void:
	if _done:
		return
	_play_oneshot(SND_CLIMAX, "SFX", 0.0)
	_play_oneshot(SND_CLAW, "SFX", -2.0)

	# 1er scratch (modere).
	_scratch(0.34, Vector2(990, 500), 12.0, randf_range(-0.25, 0.25), 0.4, 11.0, 4)
	# 2e scratch (le plus fort) : griffure plus grande, plus de sang, gros flash.
	_scratch(1.30, Vector2(900, 545), 17.0, randf_range(2.6, 3.4), 0.6, 18.0, 7)


## Une salve : flash + shake + griffure + eclaboussures, declenchee apres `delay`.
func _scratch(delay: float, claw_pos: Vector2, claw_scl: float, claw_rot: float,
		flash_str: float, shake_amt: float, blood_count: int) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_callback(func() -> void:
		if _done:
			return
		_flash(flash_str)
		_shake(shake_amt, 0.35)
		_spawn_claw(claw_pos, claw_scl, claw_rot)
		for i in blood_count:
			var pos := Vector2(randf_range(640.0, 1280.0), randf_range(430.0, 600.0))
			_spawn_blood(pos, randf_range(1.6, 3.4), randi() % BLOOD_VFRAMES, randf() * 0.12))


## Instancie une eclaboussure : un Sprite2D qui joue une rangee de la spritesheet.
func _spawn_blood(pos: Vector2, scl: float, row: int, delay: float) -> void:
	var spr := Sprite2D.new()
	spr.texture = BLOOD_SHEET
	spr.hframes = BLOOD_HFRAMES
	spr.vframes = BLOOD_VFRAMES
	spr.frame = row * BLOOD_HFRAMES
	spr.position = pos
	spr.scale = Vector2(scl, scl)
	spr.rotation = randf_range(-PI, PI)
	spr.modulate = Color(0.85, 0.05, 0.05)  # rouge sang plus sombre que l'orange du fond
	spr.visible = false
	_vfx.add_child(spr)

	var t := create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_callback(func() -> void: spr.visible = true)
	# Defile les frames de la rangee (du debut a la fin de l'animation).
	t.tween_property(spr, "frame", row * BLOOD_HFRAMES + BLOOD_HFRAMES - 1, 0.55) \
		.set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(spr.queue_free)


## Instancie une griffure : un Sprite2D qui joue les 8 frames une fois.
func _spawn_claw(pos: Vector2, scl: float, rot: float) -> void:
	var spr := Sprite2D.new()
	spr.texture = CLAW_SHEET
	spr.hframes = CLAW_HFRAMES
	spr.vframes = CLAW_VFRAMES
	spr.frame = 0
	spr.position = pos
	spr.scale = Vector2(scl, scl)
	spr.rotation = rot
	spr.modulate = Color(1.0, 0.92, 0.92)
	_vfx.add_child(spr)

	var t := create_tween()
	t.tween_property(spr, "frame", CLAW_HFRAMES * CLAW_VFRAMES - 1, 0.4) \
		.set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(spr.queue_free)


## Flicker facon enseigne au neon mourante sur tout le titre.
func _flicker_title() -> void:
	if _done:
		return
	var t := create_tween()
	for a in [0.2, 1.0, 0.4, 1.0, 0.1, 1.0]:
		t.tween_property(_title_box, "modulate:a", a, 0.06)


func _play_oneshot(stream: AudioStream, bus: String, db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _flash(strength: float) -> void:
	var f := get_node_or_null("Flash") as ColorRect
	if f == null:
		return
	f.modulate.a = strength
	create_tween().tween_property(f, "modulate:a", 0.0, 0.25)


func _shake(amount: float, dur: float) -> void:
	var t := create_tween()
	var steps := 6
	for i in steps:
		var off := Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		t.tween_property(_title_box, "position", off, dur / steps)
	t.tween_property(_title_box, "position", Vector2.ZERO, dur / steps)


func _make_embers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 60
	p.lifetime = 4.0
	p.position = Vector2(960, 1120)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1000, 10)
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.5, 0.12, 0.9)
	return p


func _make_fog() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 24
	p.lifetime = 8.0
	p.position = Vector2(960, 700)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1100, 300)
	p.direction = Vector2(1, 0)
	p.spread = 40.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 24.0
	p.scale_amount_min = 30.0
	p.scale_amount_max = 60.0
	p.color = Color(0.25, 0.45, 0.18, 0.10)
	return p


func _finish() -> void:
	if _done:
		return
	_done = true
	if _riser_player.playing:
		create_tween().tween_property(_riser_player, "volume_db", -40.0, 0.4)
	Transitions.change_scene(MENU_SCENE)


## Skip : n'importe quelle touche / clic passe directement au menu.
func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_finish()
	elif event is InputEventMouseButton and event.pressed:
		_finish()
