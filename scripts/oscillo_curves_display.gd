extends Control
class_name OscilloCurvesDisplay

const VP_W := 400
const VP_H := 220
const SAMPLE_COUNT := 150
const MAX_AMP      := 10.0

const CURVE_COLORS: Array[Color] = [
  Color(0.9, 0.3, 0.3),
  Color(0.3, 0.9, 0.3),
]
const BG_COL    := Color(0.04, 0.07, 0.04)
const PANEL_COL := Color(0.08, 0.11, 0.08)
const GRID_COL  := Color(0.10, 0.18, 0.10)
const TEXT_COL  := Color(0.72, 0.90, 0.72)

const TGT_1_A := 5
const TGT_1_F := 3
const TGT_1_P := 0
const TGT_2_A := 2
const TGT_2_F := 9
const TGT_2_P := 0

const GRAPH_H := 84
const GRAPH_Y0 := 20
const GRAPH_Y1 := GRAPH_Y0 + GRAPH_H + 8

var amplitudes:  Array[int] = [0, 0]
var frequencies: Array[int] = [1, 1]
var phases:      Array[int] = [0, 0]


func _ready() -> void:
  custom_minimum_size = Vector2(VP_W, VP_H)


func _sinusoid(a: int, f: int, p: int, x: float) -> float:
  return a * sin(f * x + p * PI / 10.0)

func _target_at(x: float) -> float:
  return _sinusoid(TGT_1_A, TGT_1_F, TGT_1_P, x) + _sinusoid(TGT_2_A, TGT_2_F, TGT_2_P, x)

func _player_at(x: float) -> float:
  var t := 0.0
  for i in 2:
    t += _sinusoid(amplitudes[i], frequencies[i], phases[i], x)
  return t


func _build_pts(fn: Callable, rect: Rect2) -> PackedVector2Array:
  var pts := PackedVector2Array()
  pts.resize(SAMPLE_COUNT + 1)
  for i in SAMPLE_COUNT + 1:
    var x := TAU * float(i) / float(SAMPLE_COUNT)
    var y_val: float = fn.call(x)
    pts[i] = Vector2(
      rect.position.x + rect.size.x * float(i) / float(SAMPLE_COUNT),
      rect.position.y + rect.size.y * 0.5 - (y_val / MAX_AMP) * rect.size.y * 0.4
    )
  return pts

func _build_pts_curve(idx: int, rect: Rect2) -> PackedVector2Array:
  var pts := PackedVector2Array()
  pts.resize(SAMPLE_COUNT + 1)
  for i in SAMPLE_COUNT + 1:
    var x := TAU * float(i) / float(SAMPLE_COUNT)
    var y_val := _sinusoid(amplitudes[idx], frequencies[idx], phases[idx], x)
    pts[i] = Vector2(
      rect.position.x + rect.size.x * float(i) / float(SAMPLE_COUNT),
      rect.position.y + rect.size.y * 0.5 - (y_val / MAX_AMP) * rect.size.y * 0.4
    )
  return pts


func _draw_graph_bg(r: Rect2) -> void:
  draw_rect(r, PANEL_COL)
  for i in 5:
    var y := r.position.y + r.size.y * float(i) / 4.0
    draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), GRID_COL, 0.5)
  var mid_y := r.position.y + r.size.y * 0.5
  draw_line(Vector2(r.position.x, mid_y), Vector2(r.end.x, mid_y), GRID_COL * 2.0, 1.0)
  draw_rect(r, Color(0.2, 0.35, 0.2), false, 1.0)


func _draw() -> void:
  var font := ThemeDB.fallback_font
  draw_rect(Rect2(Vector2.ZERO, size), BG_COL)
  draw_string(font, Vector2(0, 14), "Différentiel", HORIZONTAL_ALIGNMENT_CENTER, VP_W, 13, TEXT_COL)

  var r0 := Rect2(4, GRAPH_Y0, VP_W - 8, GRAPH_H)
  _draw_graph_bg(r0)
  draw_polyline(_build_pts(_target_at, r0), Color.CYAN, 2.0, true)

  var r1 := Rect2(4, GRAPH_Y1, VP_W - 8, GRAPH_H)
  _draw_graph_bg(r1)
  for i in 2:
    draw_polyline(_build_pts_curve(i, r1), CURVE_COLORS[i], 1.0, true)
  draw_polyline(_build_pts(_player_at, r1), Color.WHITE, 2.0, true)
