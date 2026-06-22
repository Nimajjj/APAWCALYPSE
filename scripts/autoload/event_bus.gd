extends Node
## Bus d'evenements global : decouple les emetteurs (ennemis, joueur) des
## reacteurs (Game, succes, HUD). Evite les dependances dures du type
## get_parent().get_parent() ou Global.game.xxx eparpillees.

signal enemy_killed(is_boss: bool)
signal wave_started(wave: int)
signal score_gained(amount: int)
signal money_gained(amount: int)
signal player_died
