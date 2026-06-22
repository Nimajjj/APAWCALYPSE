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

func _enter_tree():
	Global.in_game_ui = self


func _process(_delta):
	if Global.players.is_empty():
		return
	var player: IPlayer = Global.players[0]

	ScoreLabel.text = str(Global.game.score)
	MoneyLabel.text = str(player.money)
	HealthBar.value = player.health
	MunitionLabel.text = "{0}".format([player.weapon.current_mag])
	MunitionLabel2.text = "{0}".format([player.weapon.bullet_stock])

	# Reconstruction coûteuse : uniquement si le panneau de debug est affiché.
	if DebugLabel.visible:
		var _text: String = ""
		_text += Global.version + "\n"
		_text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
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
