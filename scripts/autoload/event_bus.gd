extends Node
## Bus d'evenements global : decouple les emetteurs (ennemis, joueur) des
## reacteurs (Game, succes, HUD). Evite les dependances dures du type
## get_parent().get_parent() ou Global.game.xxx eparpillees.

signal enemy_killed(is_boss: bool)
signal wave_started(wave: int)
signal score_gained(amount: int)
signal money_gained(amount: int)
signal player_died
signal player_damaged(amount: float)
signal shot_fired
signal shot_hit
## Progression roguelike : XP gagnee (a la mort d'un ennemi) et montee de niveau.
signal xp_gained(amount: int)
signal player_leveled_up(level: int)
