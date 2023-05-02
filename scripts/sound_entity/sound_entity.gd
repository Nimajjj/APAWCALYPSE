class_name SoundEntity
extends AudioStreamPlayer

@export_enum("sfx", "music", "gui") var group: String


func _ready():
	SoundManager.register(group, self)

func _exit_tree():
	SoundManager.remove(group, self)

func set_volume(vol: float) -> void:
	volume_db = vol
