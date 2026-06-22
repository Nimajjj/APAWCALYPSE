extends PanelContainer


@onready var music_slider: HSlider = $VBoxContainer/GridContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/GridContainer/SFXSlider
@onready var gui_slider: HSlider = $VBoxContainer/GridContainer/GUISlider


func _ready() -> void:
	# Restaure la position des sliders depuis la sauvegarde. Les value_changed
	# qui en decoulent reappliquent et persistent le volume.
	music_slider.value = SaveManager.get_slider("music")
	sfx_slider.value = SaveManager.get_slider("sfx")
	gui_slider.value = SaveManager.get_slider("gui")


func _on_music_slider_value_changed(value: float) -> void:
	_apply("music", value)


func _on_sfx_slider_value_changed(value: float) -> void:
	_apply("sfx", value)


func _on_gui_slider_value_changed(value: float) -> void:
	_apply("gui", value)


func _apply(group: String, value: float) -> void:
	SoundManager.change_volume(group, SoundManager.slider_to_db(value))
	SaveManager.set_slider(group, value)


func _on_back_button_pressed() -> void:
	visible = false
