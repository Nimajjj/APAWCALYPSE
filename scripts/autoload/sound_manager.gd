extends Node
## Gere le volume par groupe de sons. Le volume choisi est applique aux sons
## deja enregistres ET a ceux qui s'enregistrent ensuite, et persiste via
## SaveManager (charge avant ce singleton dans l'ordre des autoloads).

var groups: Dictionary = {}
var volumes: Dictionary = {}  # group -> volume_db courant


## Conversion valeur de slider (0-100) -> dB. 50 = 0 dB (formule historique
## du menu d'options, centralisee ici).
static func slider_to_db(value: float) -> float:
	return (value / 100.0) * (24.0 - (-80.0)) - 80.0 + 28.0


func _ready() -> void:
	for g in ["music", "sfx", "gui"]:
		volumes[g] = slider_to_db(SaveManager.get_slider(g))


func register(group: String, sound: SoundEntity) -> void:
	if groups.has(group):
		groups[group].append(sound)
	else:
		groups[group] = [sound]
	# Applique immediatement le volume courant du groupe au nouveau son.
	if volumes.has(group):
		sound.set_volume(volumes[group])


func remove(group: String, sound: SoundEntity) -> void:
	if groups.has(group):
		if sound in groups[group]:
			groups[group].erase(sound)


func change_volume(group: String, vol: float) -> void:
	volumes[group] = vol
	if !groups.has(group): return

	for s in groups[group]:
		s.set_volume(vol)
