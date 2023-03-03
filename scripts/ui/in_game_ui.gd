extends CanvasLayer

@onready var DebugLabel: RichTextLabel = $DebugLabel


func _ready():
	pass


func _process(_delta):
	var _text: String = ""
	
	_text += Global.version + "\n"
	_text += "Time: " + str(snapped(Global.game.time, 0.01)) + "\n"
	_text += "Score: " + str(Global.game.score) + "\n"
	_text += "Wave: " + str(Global.game.wave) + "\n"
	
	DebugLabel.text = _text
