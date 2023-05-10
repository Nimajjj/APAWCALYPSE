extends Interactible

@export var price: int = 300
@export var nextGain: float = 0.05
@export var maxDamageFactor: float = 3

func _ready():
	message = "Press [E] to buy damage up bonus for {0}$ (+{1}% DAMAGE)".format([price, snappedf(nextGain, 0.01)*100])


func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		player.damage_factor += snappedf(nextGain, 0.01)
		
		# Increase the price and the next gain
		nextGain = snappedf(0.05 + player.damage_factor * 0.01, 0.01)
		price = floor(price * 1.2)

		if player.damage_factor < maxDamageFactor:
			message = "Press [E] to buy damage up bonus for {0}$ (+{1}% DAMAGE)".format([price, snappedf(nextGain, 0.01)*100])
		else:
			message = "You have reached the maximum damage bonus ({0}%)".format([snappedf(maxDamageFactor, 0.01)*100])
		_on_interaction_area_2d_body_exited(player)
		_on_interaction_area_2d_body_entered(player)


func can_activate(player: IPlayer) -> bool:
	return player.money >= price && player.damage_factor < maxDamageFactor


func _on_interaction_area_2d_body_entered(body):
	if body is IPlayer:
		body.add_interactible(self)


func _on_interaction_area_2d_body_exited(body):
	if body is IPlayer:
		body.remove_interactible(self)
