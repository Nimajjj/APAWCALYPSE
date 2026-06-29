class_name SpawnTelegraph
extends Node2D
## Marqueur de spawn "style Brotato" : une croix rouge PIXEL ART posee au sol
## (aplatie pour coller a la perspective isometrique) qui clignote quelques fois
## (~1s) avant de laisser apparaitre l'ennemi, puis disparait. Emet `finished`.

signal finished

@export var blink_count: int = 3
@export var duration: float = 1.0
## Taille d'un "pixel" du marqueur (en pixels ecran).
@export var cell: float = 4.0
@export var color: Color = Color(0.86, 0.16, 0.18)

# Motif pixel art de la croix (7x7). '#': plein, ' ': vide.
const PATTERN := [
	"  ###  ",
	"  ###  ",
	"#######",
	"#######",
	"#######",
	"  ###  ",
	"  ###  ",
]
# Aplatissement vertical pour l'effet "pose au sol" (projection isometrique).
const GROUND_SQUASH := 0.6

var _emitted: bool = false


func _ready() -> void:
	z_index = 1
	scale.y = GROUND_SQUASH
	var per: float = duration / float(max(1, blink_count))
	var t := create_tween()
	for i in blink_count:
		t.tween_property(self, "modulate:a", 0.12, per * 0.5)
		t.tween_property(self, "modulate:a", 1.0, per * 0.5)
	t.finished.connect(_on_blink_finished)


func _on_blink_finished() -> void:
	if _emitted:
		return
	_emitted = true
	finished.emit()
	queue_free()


func _draw() -> void:
	var rows: int = PATTERN.size()
	var cols: int = PATTERN[0].length()
	var origin := Vector2(-cols * cell, -rows * cell) * 0.5
	var dark: Color = color.darkened(0.45)
	var ol: float = max(1.0, cell * 0.25)

	# Corps : un bloc rouge par cellule pleine.
	for y in rows:
		for x in cols:
			if _filled(x, y):
				draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)), color, true)

	# Contour sombre : seulement sur la silhouette exterieure (look pixel propre).
	for y in rows:
		for x in cols:
			if not _filled(x, y):
				continue
			var p: Vector2 = origin + Vector2(x, y) * cell
			if not _filled(x, y - 1):
				draw_rect(Rect2(p, Vector2(cell, ol)), dark, true)
			if not _filled(x, y + 1):
				draw_rect(Rect2(p + Vector2(0, cell - ol), Vector2(cell, ol)), dark, true)
			if not _filled(x - 1, y):
				draw_rect(Rect2(p, Vector2(ol, cell)), dark, true)
			if not _filled(x + 1, y):
				draw_rect(Rect2(p + Vector2(cell - ol, 0), Vector2(ol, cell)), dark, true)


func _filled(x: int, y: int) -> bool:
	if y < 0 or y >= PATTERN.size():
		return false
	var line: String = PATTERN[y]
	if x < 0 or x >= line.length():
		return false
	return line[x] == "#"
