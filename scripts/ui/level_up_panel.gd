class_name LevelUpPanel
extends CanvasLayer
## Panneau de montee de niveau (style roguelike) : voile sombre + 3 cartes
## d'ameliorations. Construit entierement par code (aucun asset ni scene).
##
## Selection : clic sur une carte, ou touches 1/2/3. Fonctionne en pause (le jeu
## est fige pendant le choix) grace a PROCESS_MODE_ALWAYS.

signal chosen(upgrade: Upgrade)

const PANEL_BG := Color(0.12, 0.12, 0.18, 0.97)
const CARD_BG := Color(0.16, 0.16, 0.23, 1.0)
const ACCENT := Color(1, 0.85, 0.3)

var _choices: Array[Upgrade] = []
var _cards: Array[Control] = []
var _locked: bool = false


func _ready() -> void:
	layer = 130  # au-dessus du HUD (in_game_ui) et des notifications
	process_mode = Node.PROCESS_MODE_ALWAYS


## Remplit le panneau avec les ameliorations proposees pour `level`.
func setup(choices: Array, level: int) -> void:
	_choices.assign(choices)
	_build_ui(level)


func _build_ui(level: int) -> void:
	# Voile plein ecran assombrissant le jeu.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	# Titre.
	var title := Label.new()
	title.text = "NIVEAU %d — CHOISIS UNE AMELIORATION" % level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	col.add_child(title)

	# Rangee de cartes.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)

	for i in _choices.size():
		var card := _make_card(_choices[i], i)
		row.add_child(card)
		_cards.append(card)

	# Rappel des touches.
	var hint := Label.new()
	hint.text = "Clique une carte ou appuie sur 1 / 2 / 3"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	col.add_child(hint)

	# Petite apparition (echelle + fondu).
	col.modulate.a = 0.0
	col.pivot_offset = col.size / 2.0
	col.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.tween_property(col, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(col, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_card(up: Upgrade, index: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 300)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = up.color
	sb.set_content_margin_all(18)
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)

	# Numero + categorie.
	var head := Label.new()
	head.text = "%d.  %s" % [index + 1, up.category_label()]
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
	vb.add_child(head)

	# Icone (glyphe ASCII teinte dans une pastille).
	var icon := Label.new()
	icon.text = up.icon
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(0, 72)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 48)
	icon.add_theme_color_override("font_color", up.color)
	icon.add_theme_color_override("font_outline_color", Color.BLACK)
	icon.add_theme_constant_override("outline_size", 5)
	vb.add_child(icon)

	# Titre de l'amelioration.
	var name_lbl := Label.new()
	name_lbl.text = up.title
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(name_lbl)

	# Description.
	var desc := Label.new()
	desc.text = up.desc
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.82, 0.85, 0.9))
	vb.add_child(desc)

	# Interactions souris : surbrillance au survol + selection au clic.
	card.mouse_entered.connect(func(): _hover(card, up.color, true))
	card.mouse_exited.connect(func(): _hover(card, up.color, false))
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select(index))
	return card


## Accentue une carte au survol (fond legerement eclairci + bordure plus vive).
func _hover(card: PanelContainer, col: Color, on: bool) -> void:
	var sb := card.get_theme_stylebox("panel") as StyleBoxFlat
	sb.bg_color = CARD_BG.lerp(col, 0.22) if on else CARD_BG
	sb.set_border_width_all(4 if on else 3)
	card.pivot_offset = card.size / 2.0
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(1.05, 1.05) if on else Vector2.ONE, 0.08)


func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1: _select(0)
			KEY_2, KEY_KP_2: _select(1)
			KEY_3, KEY_KP_3: _select(2)


func _select(index: int) -> void:
	if _locked or index < 0 or index >= _choices.size():
		return
	_locked = true
	chosen.emit(_choices[index])
