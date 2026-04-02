extends Control

signal game_closed(won: bool)

const WORD_LENGTH  := 6
const MAX_ATTEMPTS := 6

const COLOR_BG        := Color(0.07, 0.07, 0.10, 0.97)
const COLOR_PANEL     := Color(0.12, 0.12, 0.15, 1.0)
const COLOR_CELL_IDLE := Color(0.20, 0.20, 0.23, 1.0)
const COLOR_CORRECT   := Color(0.11, 0.44, 0.89, 1.0)   # bleu  = bonne position
const COLOR_PRESENT   := Color(0.93, 0.77, 0.08, 1.0)   # jaune = mauvaise position
const COLOR_ABSENT    := Color(0.26, 0.26, 0.28, 1.0)   # gris  = absent

const FAKE_WORDS := ["ZXQKWJ", "BVWQKZ", "XZWQKV", "QZKWVX"]
const REAL_WORDS := [
  "GROTTE", "FLAQUE", "BOUCHE", "PELAGE", "CRIARD",
  "VOLCAN", "PLONGE", "TRUITE", "BLAGUE", "MIROIR",
]

var _target: String = ""
var _has_dictionary: bool = false
var _row: int = 0
var _col: int = 1   # colonne 0 = lettre pré-remplie
var _won: bool = false
var _panels: Array = []
var _labels: Array = []
var _result_label: Label
var _close_btn: Button

func setup(has_dictionary: bool) -> void:
  _has_dictionary = has_dictionary
  var words: Array = REAL_WORDS if has_dictionary else FAKE_WORDS
  _target = words[randi() % words.size()].to_upper()
  _build_ui()

# ── Construction de l'UI ──────────────────────────────────────────────────────

func _build_ui() -> void:
  set_anchors_preset(Control.PRESET_FULL_RECT)

  var bg := ColorRect.new()
  bg.set_anchors_preset(Control.PRESET_FULL_RECT)
  bg.color = COLOR_BG
  add_child(bg)

  var panel := Panel.new()
  panel.anchor_left   = 0.28
  panel.anchor_right  = 0.72
  panel.anchor_top    = 0.04
  panel.anchor_bottom = 0.96
  var ps := StyleBoxFlat.new()
  ps.bg_color = COLOR_PANEL
  ps.corner_radius_top_left     = 10
  ps.corner_radius_top_right    = 10
  ps.corner_radius_bottom_left  = 10
  ps.corner_radius_bottom_right = 10
  panel.add_theme_stylebox_override("panel", ps)
  add_child(panel)

  var vbox := VBoxContainer.new()
  vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
  vbox.add_theme_constant_override("separation", 10)
  vbox.offset_left = 24; vbox.offset_right  = -24
  vbox.offset_top  = 20; vbox.offset_bottom = -20
  panel.add_child(vbox)

  var title := Label.new()
  title.text = "SUTOM"
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
  title.add_theme_font_size_override("font_size", 36)
  vbox.add_child(title)

  var hint := Label.new()
  hint.text = "Mot de %d lettres  •  Commence par « %s »" % [WORD_LENGTH, _target[0]]
  hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
  hint.add_theme_font_size_override("font_size", 13)
  vbox.add_child(hint)

  var grid := GridContainer.new()
  grid.columns = WORD_LENGTH
  grid.add_theme_constant_override("h_separation", 6)
  grid.add_theme_constant_override("v_separation", 6)
  var center := CenterContainer.new()
  center.size_flags_vertical = Control.SIZE_EXPAND_FILL
  center.add_child(grid)
  vbox.add_child(center)

  for r in range(MAX_ATTEMPTS):
    var row_p: Array = []
    var row_l: Array = []
    for c in range(WORD_LENGTH):
      var cell := Panel.new()
      cell.custom_minimum_size = Vector2(56, 56)
      var cs := StyleBoxFlat.new()
      cs.bg_color = COLOR_CELL_IDLE
      cs.border_width_left   = 2
      cs.border_width_right  = 2
      cs.border_width_top    = 2
      cs.border_width_bottom = 2
      cs.border_color = Color(0.38, 0.38, 0.42)
      cs.corner_radius_top_left     = 4
      cs.corner_radius_top_right    = 4
      cs.corner_radius_bottom_left  = 4
      cs.corner_radius_bottom_right = 4
      cell.add_theme_stylebox_override("panel", cs)

      var lbl := Label.new()
      lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
      lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
      lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
      lbl.add_theme_font_size_override("font_size", 26)
      lbl.add_theme_color_override("font_color", Color.WHITE)
      cell.add_child(lbl)
      grid.add_child(cell)
      row_p.append(cell)
      row_l.append(lbl)
    _panels.append(row_p)
    _labels.append(row_l)

  # Première lettre pré-remplie sur toutes les lignes
  for r in range(MAX_ATTEMPTS):
    _labels[r][0].text = _target[0]
    _set_color(r, 0, COLOR_CORRECT)

  _result_label = Label.new()
  _result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _result_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
  _result_label.add_theme_font_size_override("font_size", 15)
  _result_label.visible = false
  vbox.add_child(_result_label)

  _close_btn = Button.new()
  _close_btn.text = "Fermer"
  _close_btn.visible = false
  _close_btn.pressed.connect(_close)
  vbox.add_child(_close_btn)

  var instr := Label.new()
  instr.text = "Entrée : valider   •   ⌫ : effacer   •   Échap : fermer"
  instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  instr.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
  instr.add_theme_font_size_override("font_size", 11)
  vbox.add_child(instr)

func _set_color(row: int, col: int, color: Color) -> void:
  var s := StyleBoxFlat.new()
  s.bg_color = color
  s.corner_radius_top_left     = 4
  s.corner_radius_top_right    = 4
  s.corner_radius_bottom_left  = 4
  s.corner_radius_bottom_right = 4
  _panels[row][col].add_theme_stylebox_override("panel", s)

# ── Saisie clavier ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
  if not visible:
    return
  if not (event is InputEventKey and event.pressed):
    return
  get_viewport().set_input_as_handled()

  # Après fin de partie, seul Échap est traité
  var game_over := _won or _row >= MAX_ATTEMPTS
  match event.keycode:
    KEY_ESCAPE:
      _close()
    KEY_ENTER, KEY_KP_ENTER:
      if not game_over:
        _submit()
    KEY_BACKSPACE:
      if not game_over:
        _backspace()
    _:
      if not game_over and event.keycode >= KEY_A and event.keycode <= KEY_Z:
        _type(char(event.keycode).to_upper())

func _type(letter: String) -> void:
  if _row >= MAX_ATTEMPTS or _col >= WORD_LENGTH:
    return
  _labels[_row][_col].text = letter
  _col += 1

func _backspace() -> void:
  if _col <= 1:
    return
  _col -= 1
  _labels[_row][_col].text = ""

# ── Logique de jeu ────────────────────────────────────────────────────────────

func _submit() -> void:
  if _col < WORD_LENGTH or _row >= MAX_ATTEMPTS:
    return

  var guess := ""
  for c in range(WORD_LENGTH):
    guess += _labels[_row][c].text

  var colors := _evaluate(guess)
  for c in range(WORD_LENGTH):
    _set_color(_row, c, colors[c])

  var won := (guess == _target)
  _row += 1
  _col = 1

  if won:
    _won = true
    _result_label.text = "Bravo ! Le mot était bien « %s » !" % _target
    _result_label.visible = true
    _close_btn.visible = true
  elif _row >= MAX_ATTEMPTS:
    _result_label.text = "Perdu... Le mot était « %s »." % _target
    _result_label.visible = true
    _close_btn.visible = true

func _evaluate(guess: String) -> Array:
  var result := []
  result.resize(WORD_LENGTH)
  result.fill(COLOR_ABSENT)

  # Copie des lettres cibles pour consommation
  var remaining: Array = []
  for i in range(WORD_LENGTH):
    remaining.append(_target[i])

  # Passe 1 : bonnes positions
  for i in range(WORD_LENGTH):
    if guess[i] == _target[i]:
      result[i] = COLOR_CORRECT
      remaining[i] = ""

  # Passe 2 : présents mais mal placés
  for i in range(WORD_LENGTH):
    if result[i] == COLOR_CORRECT:
      continue
    var idx: int = remaining.find(guess[i])
    if idx != -1:
      result[i] = COLOR_PRESENT
      remaining[idx] = ""

  return result

func _close() -> void:
  game_closed.emit(_won)
  queue_free()
