extends CanvasLayer

@onready var DebugLabel: RichTextLabel = $DebugLabel
@onready var InteractibleLabel: Label = $InteractibleLabel
@onready var MoneyLabel: Label = $MoneyLabel
@onready var ScoreLabel: Label = $ScoreLabel
@onready var HealthBar: ProgressBar = $HealthBar
@onready var MunitionLabel: Label = $MunitionLabel
@onready var MunitionLabel2: Label = $MunitionLabel2

func _enter_tree():
	Global.in_game_ui = self


func _process(_delta):
	ScoreLabel.text = str(Global.game.score)
	MoneyLabel.text = str(Global.players[0].money)
	HealthBar.value = Global.players[0].health
	MunitionLabel.text = "{0}".format([
		Global.players[0].weapon.current_mag
	])
	MunitionLabel2.text = "{0}".format([
		Global.players[0].weapon.bullet_stock,
	])
	
	var _text: String = ""
	_text += Global.version + "\n"
	_text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
	_text += "Time: " + str(snapped(Global.game.time, 0.01)) + "\n"
	_text += "Score: " + str(Global.game.score) + "\n"
	_text += "Wave: " + str(Global.game.wave) + "\n"
	
	if Global.players.size() > 0:
		_text += "Money: " + str(Global.players[0].money) + "\n"
		_text += "Health: " + str(Global.players[0].health) + "\n"
		_text += "Current Mag: " + str(Global.players[0].weapon.current_mag) + "\n"
		_text += "Mag Capacity: " + str(Global.players[0].weapon.mag_capacity) + "\n"
		_text += "Bullet Stock: " + str(Global.players[0].weapon.bullet_stock) + "\n"
		_text += "Max Bullet Stock: " + str(Global.players[0].weapon.max_bullet_stock) + "\n"
		_text += "Stock Factor: " + str(Global.players[0].weapon.stock_factor) + "\n"

	DebugLabel.text = _text
