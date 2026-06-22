extends Node
## Succes data-driven. Verifies pendant la partie, persistes via SaveManager.

signal achievement_unlocked(id: String, title: String, description: String)

const DEFS := {
	"first_blood":  {"title": "Premier Sang",   "desc": "Tuer un ennemi"},
	"hunter":       {"title": "Chasseur",        "desc": "50 ennemis tues (cumul)"},
	"exterminator": {"title": "Exterminateur",   "desc": "500 ennemis tues (cumul)"},
	"survivor":     {"title": "Survivant",       "desc": "Atteindre la vague 5"},
	"veteran":      {"title": "Veteran",         "desc": "Atteindre la vague 10"},
	"boss_slayer":  {"title": "Tueur de Boss",   "desc": "Tuer un boss"},
	"rich_cat":     {"title": "Chat Fortune",    "desc": "Gagner 10 000 d'argent (cumul)"},
	"persistent":   {"title": "Acharne",         "desc": "Jouer 10 parties"},
}


func _unlock(id: String) -> void:
	if not DEFS.has(id):
		return
	if SaveManager.is_unlocked(id):
		return
	SaveManager.mark_unlocked(id)
	achievement_unlocked.emit(id, DEFS[id].title, DEFS[id].desc)


## Appele a chaque mort d'ennemi (run_kills = total tues dans la partie en cours).
func on_enemy_killed(is_boss: bool, run_kills: int) -> void:
	var cumulative := SaveManager.total_kills + run_kills
	if cumulative >= 1:
		_unlock("first_blood")
	if cumulative >= 50:
		_unlock("hunter")
	if cumulative >= 500:
		_unlock("exterminator")
	if is_boss:
		_unlock("boss_slayer")


## Appele au demarrage de chaque vague.
func on_wave_reached(wave: int) -> void:
	if wave >= 5:
		_unlock("survivor")
	if wave >= 10:
		_unlock("veteran")


## Appele apres l'enregistrement d'une partie (totaux a jour). Verifie aussi les
## paliers cumulatifs de kills pour un deblocage immediat en fin de partie.
func on_run_recorded() -> void:
	if SaveManager.total_kills >= 50:
		_unlock("hunter")
	if SaveManager.total_kills >= 500:
		_unlock("exterminator")
	if SaveManager.total_money >= 10000:
		_unlock("rich_cat")
	if SaveManager.games_played >= 10:
		_unlock("persistent")


func unlocked_count() -> int:
	var n := 0
	for id in DEFS:
		if SaveManager.is_unlocked(id):
			n += 1
	return n
