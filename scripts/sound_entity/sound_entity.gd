class_name SoundEntity
extends AudioStreamPlayer

@export_enum("sfx", "music", "gui") var group: String


func _ready():
	# Route vers le bus du groupe pour etre pilote par les sliders d'options.
	if SoundManager.GROUP_BUS.has(group):
		bus = SoundManager.GROUP_BUS[group]
	SoundManager.register(group, self)

func _exit_tree():
	SoundManager.remove(group, self)

func set_volume(vol: float) -> void:
	volume_db = vol
