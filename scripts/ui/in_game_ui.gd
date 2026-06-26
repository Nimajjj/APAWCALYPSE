extends CanvasLayer

@onready var DebugLabel: RichTextLabel = $DebugLabel
@onready var InteractibleLabel: Label = $InteractibleLabel
@onready var MoneyLabel: Label = $MoneyLabel
@onready var ScoreLabel: Label = $ScoreLabel
@onready var HealthBar: ProgressBar = $HealthBar
@onready var MunitionLabel: Label = $MunitionLabel
@onready var MunitionLabel2: Label = $MunitionLabel2
@onready var BonusesOverlay: TextureRect = $BonusesOverlay
@onready var BonusesHBox: HBoxContainer = $BonusesOverlay/BonusesHBox
@onready var Portrait: TextureRect = $Portrait

var _last_player_count: int = -1
var _last_health: float = -1.0
var _objective_label: Label

func _enter_tree():
	Global.in_game_ui = self


func _ready() -> void:
	# Panneau de debug : visible seulement en build debug/editeur, bascule par F3.
	DebugLabel.visible = OS.is_debug_build()

	# Indicateur d'objectif (vague + ennemis restants), cree par code pour
	# eviter de modifier la scene a la main.
	_objective_label = Label.new()
	_objective_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_objective_label.offset_top = 14.0
	_objective_label.offset_bottom = 56.0
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.add_theme_font_size_override("font_size", 28)
	_objective_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_objective_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_objective_label.add_theme_constant_override("outline_size", 5)
	add_child(_objective_label)


func _process(_delta):
	if Global.players.is_empty():
		return
	var player: IPlayer = Global.players[0]

	if _objective_label != null:
		_objective_label.text = "VAGUE %d   -   Ennemis restants : %d" % [Global.game.wave, Global.units_alive]

	ScoreLabel.text = str(Global.game.score)
	MoneyLabel.text = str(player.money)
	HealthBar.value = player.health
	if _last_health >= 0.0 and player.health < _last_health:
		_pulse(HealthBar)
	_last_health = player.health
	MunitionLabel.text = "{0}".format([player.weapon.current_mag])
	# Reserve de munitions desormais infinie.
	MunitionLabel2.text = "∞"

	# Reconstruction coûteuse : uniquement si le panneau de debug est affiché.
	if DebugLabel.visible:
		var _text: String = ""
		_text += Global.version + "\n"
		_text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
		_text += "Draw calls: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) + "\n"
		_text += "Nodes: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) + "\n"
		_text += "RAM: " + str(snapped(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1)) + " Mo\n"
		_text += "Proc/Phys ms: " + str(snapped(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01)) + " / " + str(snapped(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01)) + "\n"
		_text += "Time: " + str(snapped(Global.game.time, 0.01)) + "\n"
		_text += "Score: " + str(Global.game.score) + "\n"
		_text += "Wave: " + str(Global.game.wave) + "\n"
		_text += "Money: " + str(player.money) + "\n"
		_text += "Health: " + str(player.health) + "\n"
		_text += "Speed: " + str(player.speed) + "\n"
		_text += "Damage Factor: " + str(player.damage_factor) + "\n"
		_text += "Reload Factor: " + str(player.reload_factor) + "\n"
		_text += "Current Mag: " + str(player.weapon.current_mag) + "\n"
		_text += "Mag Capacity: " + str(player.weapon.mag_capacity) + "\n"
		_text += "Bullet Stock: " + str(player.weapon.bullet_stock) + "\n"
		_text += "Max Bullet Stock: " + str(player.weapon.max_bullet_stock) + "\n"
		_text += "Stock Factor: " + str(player.weapon.stock_factor) + "\n"
		DebugLabel.text = _text

	var active_bonuses: Array = player.active_bonus
	for bonus in BonusesHBox.get_children():
		if bonus.name.to_lower() in active_bonuses:
			bonus.modulate = Color(1, 1, 1, 1.5)
		else:
			bonus.modulate = Color(1, 1, 1, 0.39)

	# Le portrait ne dépend que du nombre de joueurs : on évite une
	# réaffectation (et mutation de texture) inutile à chaque frame.
	if _last_player_count != Global.players.size():
		_last_player_count = Global.players.size()
		for i in range(Global.players.size()):
			Portrait.texture.region = Rect2(0, 32 * (i + 3), 32, 32)


func stop_reloading() -> void:
	$AnimationPlayer.stop()
	$TextureRect.visible = true
	$TextureRect2.visible = false

func reloading() -> void:
	$AnimationPlayer.play("reload")


## Petit pulse d'echelle pour attirer l'oeil (ex. barre de vie qui baisse).
func _pulse(ctrl: Control) -> void:
	ctrl.pivot_offset = ctrl.size / 2.0
	var t := create_tween()
	t.tween_property(ctrl, "scale", Vector2(1.18, 1.18), 0.06)
	t.tween_property(ctrl, "scale", Vector2.ONE, 0.14)


func _input(event: InputEvent) -> void:
	# F3 : afficher/masquer le panneau de debug.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		DebugLabel.visible = not DebugLabel.visible
