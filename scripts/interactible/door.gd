extends Interactible

@export var price: int = 100
@export var open: bool = false
@export var spawner_id: int = -1
@export var door_group: String

func _ready():
	message = "Press [E] to open the door for {0}$".format([price])
	add_to_group(door_group)
	
func activate(player: IPlayer) -> void:
	if can_activate(player) :
		open = true
		player.money -= price
		visible	 = false
		
		if spawner_id != -1:
			var spawners := get_tree().get_nodes_in_group("spawners")
			for spawner in spawners:
				if spawner.id == spawner_id:
					spawner.enabled = true
		queue_free()
	
		get_tree().call_group(door_group,"queue_free")
			
		
func can_activate(player: IPlayer) -> bool:
	return player.money >= price && !open


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)
