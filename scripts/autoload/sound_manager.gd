extends Node
## Gere le volume par groupe de sons via les bus audio (Master/Music/SFX/GUI).
## Piloter les bus garantit que TOUS les sons d'un groupe sont affectes, y compris
## les AudioStreamPlayer bruts (armes, ennemis, pumps...) qui ne passent pas par
## SoundEntity. Le volume choisi persiste via SaveManager (charge avant ce
## singleton dans l'ordre des autoloads).

# group logique -> nom du bus audio
const GROUP_BUS := {"music": "Music", "sfx": "SFX", "gui": "GUI"}

var groups: Dictionary = {}
var volumes: Dictionary = {}  # group -> volume_db courant


## Conversion valeur de slider (0-100) -> dB. 0 = silence total, 100 = 0 dB.
## Echelle perceptuelle (linear_to_db) pour un fondu naturel.
static func slider_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(clampf(value / 100.0, 0.0, 1.0))


func _ready() -> void:
	for g in GROUP_BUS.keys():
		_apply_bus(g, slider_to_db(SaveManager.get_slider(g)))


func register(group: String, sound: SoundEntity) -> void:
	if groups.has(group):
		groups[group].append(sound)
	else:
		groups[group] = [sound]


func remove(group: String, sound: SoundEntity) -> void:
	if groups.has(group):
		if sound in groups[group]:
			groups[group].erase(sound)


func change_volume(group: String, vol: float) -> void:
	_apply_bus(group, vol)


## Applique le volume au bus du groupe et coupe vraiment le bus au silence.
func _apply_bus(group: String, vol: float) -> void:
	volumes[group] = vol
	if not GROUP_BUS.has(group):
		return
	var idx := AudioServer.get_bus_index(GROUP_BUS[group])
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, vol <= -79.0)
	AudioServer.set_bus_volume_db(idx, vol)
