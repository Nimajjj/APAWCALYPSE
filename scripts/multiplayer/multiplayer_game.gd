extends Game


func _ready():
	print("Starting multiplayer game scene")
	
	GameTimer.start()
	
	var spawners := get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		Global.spawners.append(spawner as ISpawner)
