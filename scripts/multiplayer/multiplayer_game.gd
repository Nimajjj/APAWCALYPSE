extends Game

var started: bool = false

func _ready():	
	Utils.log("Starting multiplayer game scene", Utils.LOG_INFO)
	
	var spawners := get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		Global.spawners.append(spawner as ISpawner)


func _new_player() -> void:
	if !started:
		if multiplayer.is_server():
			new_wave()
			GameTimer.start()
			started = true
			Utils.log("GameTimer.is_stopped() = {0}".format([GameTimer.is_stopped()]))

