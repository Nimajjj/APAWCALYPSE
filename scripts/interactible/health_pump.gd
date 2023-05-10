extends Interactible

@export var price: int = 100
@export var nextGain: int = 10
@export var maxHealth: int = 4000

func _ready():
	message = "Press [E] to buy health up bonus for {0}$ (+{1} HP)".format([price, nextGain])

func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		player.max_health += nextGain
		
		# Heal the player with gained hps.
		player.health += nextGain

		# Increase the price and the next gain
		nextGain = 10 + player.max_health * 0.01
		price = floor(price * 1.2)

		if(player.max_health < maxHealth):
			message = "Press [E] to buy health up bonus for {0}$ (+{1} HP)".format([price, nextGain])
		else:
			message = "You have reached the maximum health bonus."
		_on_interaction_area_2d_body_exited(player)
		_on_interaction_area_2d_body_entered(player)


func can_activate(player: IPlayer) -> bool:
	return player.money >= price and player.max_health < maxHealth


func _on_interaction_area_2d_body_entered(body):
	if body is IPlayer:
		body.add_interactible(self)


func _on_interaction_area_2d_body_exited(body):
	if body is IPlayer:
		body.remove_interactible(self)
