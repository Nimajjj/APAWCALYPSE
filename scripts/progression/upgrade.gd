class_name Upgrade
extends RefCounted
## Description d'une amelioration roguelike proposee a la montee de niveau.
##
## Une amelioration porte ses metadonnees d'affichage (titre, description, icone
## ASCII, couleur, categorie) et deux Callables :
##  - `_apply`    : func(player: IPlayer) -> void   applique l'effet
##  - `_can_offer`: func(player: IPlayer) -> bool   (optionnel) filtre l'offre
##
## Le nombre de fois qu'une amelioration a deja ete prise est suivi par
## Progression ; `max_stacks` (-1 = illimite) borne les repetitions.

enum Category { STAT, ITEM, WEAPON, ABILITY }

var id: String
var title: String
var desc: String
var category: int = Category.STAT
var color: Color = Color.WHITE
var icon: String = "+"
var max_stacks: int = -1

var _apply: Callable
var _can_offer: Callable


func _init(p_id: String, p_title: String, p_desc: String, p_category: int,
		p_color: Color, p_icon: String, p_apply: Callable,
		p_max_stacks: int = -1, p_can_offer: Callable = Callable()) -> void:
	id = p_id
	title = p_title
	desc = p_desc
	category = p_category
	color = p_color
	icon = p_icon
	_apply = p_apply
	max_stacks = p_max_stacks
	_can_offer = p_can_offer


## Vrai si l'amelioration peut encore etre proposee (stacks non epuises + filtre
## contextuel optionnel satisfait).
func can_offer(player: IPlayer, taken_count: int) -> bool:
	if max_stacks >= 0 and taken_count >= max_stacks:
		return false
	if _can_offer.is_valid():
		return _can_offer.call(player)
	return true


func apply(player: IPlayer) -> void:
	_apply.call(player)


## Libelle court de categorie (affiche sur la carte).
func category_label() -> String:
	match category:
		Category.STAT: return "STAT"
		Category.ITEM: return "OBJET"
		Category.WEAPON: return "ARME"
		Category.ABILITY: return "CAPACITE"
	return ""
