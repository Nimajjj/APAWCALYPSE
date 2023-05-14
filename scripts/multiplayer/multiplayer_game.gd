extends Game

var started: bool = false

func _ready():
	print("Starting multiplayer game scene")
	
	GameTimer.start()
	
	var spawners := get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		Global.spawners.append(spawner as ISpawner)


func _new_player() -> void:
	if !started:
		if multiplayer.is_server():
			_new_wave()

func _new_wave() -> void:
	new_wave()
	started = true
