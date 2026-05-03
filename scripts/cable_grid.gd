extends Control
class_name CableGrid

const GRILLE_W    := 12
const GRILLE_H    := 16
const TAILLE_CELL := 40
const MARGE       := 12
const VP_W := MARGE * 2 + GRILLE_W * TAILLE_CELL  # 540
const VP_H := MARGE * 2 + GRILLE_H * TAILLE_CELL  # 680
const NOMS := ["rouge", "vert", "bleu", "jaune"]

const PALETTE := {
  "rouge": Color(0.85, 0.20, 0.20),
  "vert":  Color(0.18, 0.78, 0.18),
  "bleu":  Color(0.18, 0.42, 0.92),
  "jaune": Color(0.92, 0.83, 0.10),
}

# ── État (mis à jour par computer_machine.gd avant queue_redraw) ────────────
var endpoints:     Dictionary = {}
var chemins:       Dictionary = {}
var en_dessin:     bool       = false
var col_dessin:    String     = ""
var crt:           Array      = []
var drag_ep                         # null | {"couleur": String, "idx": int}
var drag_pos:      Vector2    = Vector2.ZERO
var peut_deplacer: bool       = false
var depl_restants: int        = 2


func _ready() -> void:
  custom_minimum_size = Vector2(VP_W, VP_H)
  mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Dessin ───────────────────────────────────────────────────────────────────

func _draw() -> void:
  for c in NOMS:
    if chemins.get(c, []).size() > 1:
      _draw_chemin(chemins[c], PALETTE[c])
  if en_dessin and crt.size() > 0:
    _draw_chemin(crt, PALETTE[col_dessin].lightened(0.30))
  _draw_endpoints()
  if drag_ep != null:
    _draw_ep(drag_pos, PALETTE[drag_ep["couleur"]].lightened(0.35), false)


func _draw_endpoints() -> void:
  for c in NOMS:
    if not endpoints.has(c):
      continue
    for i in 2:
      if drag_ep != null and drag_ep["couleur"] == c and drag_ep["idx"] == i:
        continue
      _draw_ep(_centre(endpoints[c][i]), PALETTE[c], peut_deplacer and depl_restants > 0)


func _draw_chemin(cells: Array, col: Color) -> void:
  var r := TAILLE_CELL * 0.35
  for i in cells.size() - 1:
    var a := _centre(cells[i])
    var b := _centre(cells[i + 1])
    var perp := (b - a).normalized().rotated(PI * 0.5) * r
    draw_colored_polygon(PackedVector2Array([a + perp, a - perp, b - perp, b + perp]), col)
  for cell in cells:
    draw_circle(_centre(cell), r, col)


func _draw_ep(pos: Vector2, col: Color, halo: bool) -> void:
  var r := TAILLE_CELL * 0.40
  if halo:
    draw_circle(pos, r + 5.0, Color(1.0, 1.0, 1.0, 0.50))
  draw_circle(pos, r, col)
  draw_arc(pos, r, 0.0, TAU, 32, col.lightened(0.5), 2.0)


# ── Utilitaires ──────────────────────────────────────────────────────────────

func _centre(c: Vector2i) -> Vector2:
  return Vector2(
    MARGE + c.x * TAILLE_CELL + TAILLE_CELL * 0.5,
    MARGE + c.y * TAILLE_CELL + TAILLE_CELL * 0.5
  )
