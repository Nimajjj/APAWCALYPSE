extends PanelContainer


@onready var music_slider: HSlider = $VBoxContainer/GridContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/GridContainer/SFXSlider
@onready var gui_slider: HSlider = $VBoxContainer/GridContainer/GUISlider


func _on_music_slider_value_changed(value):
	var val: float = (value / 100) * (24 - (-80)) -80 + 28
	SoundManager.change_volume("music", val)


func _on_sfx_slider_value_changed(value):
	var val: float = (value / 100) * (24 - (-80)) -80 + 28
	SoundManager.change_volume("sfx", val)


func _on_gui_slider_value_changed(value):
	var val: float = (value / 100) * (24 - (-80)) -80 + 28
	SoundManager.change_volume("gui", value)


func _on_back_button_pressed():
	visible = false
