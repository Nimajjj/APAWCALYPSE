extends Node
## Persistance de la progression long terme dans user://save.cfg.
## Ne stocke que des statistiques de jeu (aucune donnee sensible).

const SAVE_PATH := "user://save.cfg"

var high_score: int = 0
var best_wave: int = 0
var total_kills: int = 0
var total_money: int = 0
var games_played: int = 0
var unlocked: Dictionary = {}  # id_succes -> true
var sliders: Dictionary = {"music": 50.0, "sfx": 50.0, "gui": 50.0}  # reglages volume (0-100)


func _ready() -> void:
	load_game()


func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return  # pas encore de sauvegarde : on garde les valeurs par defaut
	high_score = int(cfg.get_value("stats", "high_score", 0))
	best_wave = int(cfg.get_value("stats", "best_wave", 0))
	total_kills = int(cfg.get_value("stats", "total_kills", 0))
	total_money = int(cfg.get_value("stats", "total_money", 0))
	games_played = int(cfg.get_value("stats", "games_played", 0))
	var u: Variant = cfg.get_value("achievements", "unlocked", {})
	if u is Dictionary:
		unlocked = u
	var s: Variant = cfg.get_value("settings", "sliders", {})
	if s is Dictionary:
		for k in sliders.keys():
			if s.has(k):
				sliders[k] = float(s[k])


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "high_score", high_score)
	cfg.set_value("stats", "best_wave", best_wave)
	cfg.set_value("stats", "total_kills", total_kills)
	cfg.set_value("stats", "total_money", total_money)
	cfg.set_value("stats", "games_played", games_played)
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.set_value("settings", "sliders", sliders)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: echec de la sauvegarde (code %d)" % err)


## Enregistre une partie terminee. Retourne les records battus.
func record_run(score: int, wave: int, kills: int, money: int) -> Dictionary:
	var new_high := score > high_score
	var new_best_wave := wave > best_wave
	if new_high:
		high_score = score
	if new_best_wave:
		best_wave = wave
	total_kills += kills
	total_money += money
	games_played += 1
	save_game()
	return {"new_high_score": new_high, "new_best_wave": new_best_wave}


func get_slider(group: String) -> float:
	return sliders.get(group, 50.0)


func set_slider(group: String, value: float) -> void:
	sliders[group] = value
	save_game()


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)


func mark_unlocked(id: String) -> void:
	unlocked[id] = true
	save_game()


func reset() -> void:
	high_score = 0
	best_wave = 0
	total_kills = 0
	total_money = 0
	games_played = 0
	unlocked = {}
	sliders = {"music": 50.0, "sfx": 50.0, "gui": 50.0}
	save_game()
