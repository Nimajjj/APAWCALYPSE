extends Interactible

@export var price: int = 100
@export var open: bool = false
@export var spawner_id: int = -1


func _ready(): 
	message = "Press [E] to open the door for {0}$".format([price])

func activate(player: IPlayer) -> void:
	if can_activate(player) :
		open = true
		player.money -= price
		visible	 = false
		
		queue_free()
		
		# activate spawners with spawner_id (olivier)


func can_activate(player: IPlayer) -> bool:
	return player.money >= price && !open


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)
