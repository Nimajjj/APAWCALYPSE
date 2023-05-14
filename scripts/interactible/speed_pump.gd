extends Interactible

@export var price: int = 300
@export var nextGain: int = 1000
@export var maxSpeed: int = 38000

func _ready():
	message = "Press [E] to buy speed up bonus for {0}$ (+{1} SPEED)".format([price, nextGain/100])

func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		player.speed += nextGain
		
		# Increase the price and the next gain
		nextGain = 1000 + player.speed * 0.02
		price = floor(price * 1.5)
		$AudioStreamPlayer.play()
		if(player.speed < maxSpeed):
			message = "Press [E] to buy speed up bonus for {0}$ (+{1} SPEED)".format([price, nextGain/100])
		else:
			message = "You have reached the maximum speed"
		_on_interaction_area_2d_body_exited(player)
		_on_interaction_area_2d_body_entered(player)
#


func can_activate(player: IPlayer) -> bool:
	return player.money >= price && player.speed < maxSpeed


func _on_interaction_area_2d_body_entered(body):
	if body is IPlayer:
		body.add_interactible(self)


func _on_interaction_area_2d_body_exited(body):
	if body is IPlayer:
		body.remove_interactible(self)
