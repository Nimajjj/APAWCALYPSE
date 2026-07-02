extends Node
## Centralise les multiplicateurs d'equilibrage du jeu (vitesses, degats, vies,
## cadence...). Les entites lisent ces valeurs a leur initialisation et se
## reabonnent au signal `changed` pour un reglage a chaud depuis le dashboard dev.
##
## Convention : ce sont des MULTIPLICATEURS appliques aux valeurs de base des
## scenes (1.0 = inchange). Pour la cadence/recharge, < 1.0 = plus rapide.

signal changed

# Cle -> [valeur_par_defaut, min, max, pas, libelle]
const DEFS := {
	"player_speed":      [1.40, 0.5, 3.0, 0.05, "Vitesse joueur"],
	"player_max_health": [1.00, 0.5, 3.0, 0.05, "Vie max joueur"],
	"player_damage":     [1.00, 0.5, 3.0, 0.05, "Degats joueur"],
	"player_reload":     [1.00, 0.3, 2.0, 0.05, "Temps de recharge"],
	"enemy_speed":       [1.35, 0.5, 3.0, 0.05, "Vitesse ennemis"],
	"enemy_health":      [1.00, 0.3, 3.0, 0.05, "Vie ennemis"],
	"enemy_damage":      [1.00, 0.3, 3.0, 0.05, "Degats ennemis"],
	"enemy_money":       [1.00, 0.3, 3.0, 0.05, "Argent lache"],
	# Scaling par vague facon Brotato : croissance LINEAIRE proportionnelle a la vie
	# de base (0.30 = +30% de la base par vague apres la 1ere). Compense la montee en
	# puissance du joueur (upgrades multiplicatives). Les boss recoivent la moitie de
	# cette croissance (cf. FabricEnemy). Vitesse volontairement non scalee (Brotato).
	"enemy_hp_per_wave":  [0.30, 0.0, 1.5, 0.05, "PV +/vague (x base)"],
	"enemy_dmg_per_wave": [0.12, 0.0, 1.0, 0.02, "Degats +/vague (x base)"],
	"weapon_fire_rate":  [1.00, 0.3, 2.0, 0.05, "Cadence de tir"],
	# Spawn "autour du joueur" (style Brotato). Ces valeurs sont des grandeurs
	# absolues (et non des multiplicateurs) mais profitent du meme dashboard.
	"spawn_near_ratio":  [0.20, 0.0, 1.0, 0.05, "Ratio spawn autour joueur"],
	"spawn_near_radius": [350.0, 100.0, 1200.0, 25.0, "Rayon spawn joueur (px)"],
}

var values: Dictionary = {}


func _ready() -> void:
	for k in DEFS.keys():
		values[k] = DEFS[k][0]


func get_v(key: String) -> float:
	return float(values.get(key, 1.0))


func set_v(key: String, value: float) -> void:
	if not DEFS.has(key):
		return
	values[key] = clampf(value, DEFS[key][1], DEFS[key][2])
	changed.emit()


func reset_defaults() -> void:
	for k in DEFS.keys():
		values[k] = DEFS[k][0]
	changed.emit()
