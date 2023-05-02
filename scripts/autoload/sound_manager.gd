extends Node

var groups: Dictionary = {}


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
	if !groups.has(group): return
	
	for s in groups[group]:
		s.set_volume(vol)

