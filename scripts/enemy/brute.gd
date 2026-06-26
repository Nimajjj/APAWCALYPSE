extends IEnemy
## Brute (inspire Brotato) : lent, tres resistant, gros degats. Resiste au
## ralentissement (slow reduit de moitie) pour rester menacant.

func slow() -> void:
	slow_timer.start()
	if not slowed:
		speed -= 10
		if speed <= 0:
			speed = 5
		slowed = true
