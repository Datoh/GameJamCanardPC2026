extends Control
class_name OscilloParamDisplay

const VP_W := 180
const VP_H := 60
const BTN_W := 52
const BTN_H := 44

const BG_COL   := Color(0.04, 0.07, 0.04)
const BTN_COL  := Color(0.14, 0.22, 0.15)
const BTN_BDR  := Color(0.25, 0.40, 0.26)
const TEXT_COL := Color(0.72, 0.90, 0.72)

var value:       int   = 0
var curve_color: Color = Color.RED


func _ready() -> void:
	custom_minimum_size = Vector2(VP_W, VP_H)


func _minus_rect() -> Rect2:
	return Rect2(4, (VP_H - BTN_H) * 0.5, BTN_W, BTN_H)

func _plus_rect() -> Rect2:
	return Rect2(VP_W - 4 - BTN_W, (VP_H - BTN_H) * 0.5, BTN_W, BTN_H)


func on_click(uv: Vector2) -> int:
	var pos := uv * Vector2(VP_W, VP_H)
	if _minus_rect().has_point(pos):
		return -1
	if _plus_rect().has_point(pos):
		return 1
	return 0


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), BG_COL)

	# Bande couleur de la courbe
	draw_rect(Rect2(VP_W * 0.5 - 10, 2, 20, 4), curve_color)

	# Bouton −
	var mr := _minus_rect()
	draw_rect(mr, BTN_COL)
	draw_rect(mr, BTN_BDR, false, 1.0)
	draw_string(font, Vector2(mr.position.x + 12, mr.end.y - 8), "−", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, TEXT_COL)

	# Valeur centrée entre les boutons
	var mid_x := mr.end.x
	var mid_w  := _plus_rect().position.x - mid_x
	draw_string(font, Vector2(mid_x, VP_H * 0.5 + 11), str(value), HORIZONTAL_ALIGNMENT_CENTER, mid_w, 22, TEXT_COL)

	# Bouton +
	var pr := _plus_rect()
	draw_rect(pr, BTN_COL)
	draw_rect(pr, BTN_BDR, false, 1.0)
	draw_string(font, Vector2(pr.position.x + 10, pr.end.y - 8), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, TEXT_COL)
