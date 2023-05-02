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
		else:
			print("sound doest not exist in " + group)
	else:
		print("group doest not exist")


func change_volume(group: String, vol: float) -> void:
	if !groups.has(group):
		print("group doest not exist")
		return
	
	for s in groups[group]:
		s.set_volume(vol)

