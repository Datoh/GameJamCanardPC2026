extends Machine
class_name MachineSutom

signal game_finished(won: bool)

const WORD_LENGTH  := 6
const MAX_ATTEMPTS := 6

const COLOR_PAPER     := Color(0.97, 0.95, 0.91)
const COLOR_CORRECT   := Color(0.73, 0.15, 0.15)
const COLOR_PRESENT   := Color(0.93, 0.77, 0.08)
const COLOR_ABSENT    := Color(0.11, 0.44, 0.89)
const COLOR_CELL_IDLE := Color(0.86, 0.84, 0.78)
const COLOR_FIRST_COL := Color(0.73, 0.15, 0.15)

@export var camera_height: float = 0.25
@export var cam_transition_duration: float = 1.0
@export var cam_arc_height: float = 1.5

var _cam_start_pos := Vector3.ZERO
var _cam_start_basis := Basis.IDENTITY
var _cam_end_pos := Vector3.ZERO
var _cam_end_basis := Basis.IDENTITY
var _close_won: bool = false

const FAKE_WORDS := ["ZXQKWJ", "BVWQKZ", "XZWQKV", "QZKWVX", "BRTKLM", "CDFGHS", "FGHRTL", "KLMRST", "PQRSTV", "BCDFGH", "NRSTVW", "MNRKLT", "DFLRTV", "GHJKLM", "BCDFLM", "NSTRVM", "ZXWVTS", "GKLMRN", "HJTKVW", "CRTSVX", "BFLNRZ", "DGHKMP", "LMNRST", "BCGNRV", "FHKLMN", "DPRSTV", "GHKLNR", "BCMRST", "DFKLNP", "GHJMRV", "BCTKVX", "LNRTVW", "CDGHJK", "FMNRSV", "BHKLRT", "DGNSTV", "CFKLMR", "BHJNPW", "GKLRTV", "CDMNRS", "BFHKLT", "DGJMNT", "CLRSTV", "BFGHNP", "DKLRTW", "CGMNRV", "BHJKLS", "DFMNTV", "GHLRST", "BCKLNW", "DFGHRS", "BJMNTV", "CKLRSW", "DGHMNP"]
const REAL_WORDS := ["PARTIE", "DEPUIS", "EQUIPE", "GROUPE", "CONTRE", "SAISON", "REGION", "PARTIR", "NOMBRE", "GUERRE", "ENCORE", "EPOQUE", "QUATRE", "SITUEE", "GRANDE", "POINTS", "TROUVE", "ANCIEN", "EGLISE", "PERMET", "ARGENT", "COMPTE", "DURANT", "ESPECE", "MEMBRE", "PROJET", "CHAQUE", "NIVEAU", "JOUEUR", "SORTIE", "TAILLE", "LANGUE", "MAISON", "FINALE", "BRONZE", "PUBLIC", "SUCCES", "AUTEUR", "RAISON", "DEVANT", "NUMERO", "SECOND", "RETOUR", "MILIEU", "EPOUSE", "RESEAU", "MODELE", "PUBLIE", "ACTEUR", "EXISTE", "GAUCHE", "AUTOUR", "CANTON", "EGLISE", "SIMPLE", "PETITE", "CLASSE", "DOUBLE", "TANDIS", "JAMAIS", "LEQUEL", "MESURE", "APPELE", "DROITE", "ACTUEL", "MARQUE", "PROPRE", "COURSE", "ACTION", "CINEMA", "JEUNES", "DIVERS", "EMPIRE", "MOMENT", "COMBAT", "SINGLE", "CENTRE", "DECIDE", "NATURE"]

var _overhead_cam: Camera3D
var _player_camera: Camera3D = null
var _player_ref: Node = null
var _vp: SubViewport = null
var _top_plane: MeshInstance3D = null
var _active: bool = false

var _target: String = ""
var _row: int = 0
var _col: int = 1
var _won: bool = false
var _panels: Array = []
var _labels: Array = []
var _result_label: Label
var _hint_label: Label

const NAME := "SUTOM"

func _ready() -> void:
  machine_name = NAME
  dialogue_demande = "sutom_demande"
  dialogue_resultat = "sutom_resultat"
  robot_work_duration = 20.0
  object_required = "Dictionnaire"
  message_not_enable = "Un SUTOM ! Non je n'ai pas le temps. Peut être plus tard..."
  message_idle = "Le mot de passe est là..."
  message_try_machine = "Impossible de trouver ce mot... je vais demander de l'aide à LN R3p14y."
  message_robot_working = "LN R3p14y est en train de faire le SUTOM... je vais le laisser faire..."
  message_robot_done = "Je devrais parler à LN R3p14y, il a l'air d'avoir terminé."
  message_try_machine_object = "Il faut que je trouve un moyen d'apprendre plus de mots."
  message_try_machine_ok = "Avec le dictionnaire, je vais connaître les mots."
  message_waiting_unlocked = "J'ai le mot de passe."
  message_solved = "Vous avez déjà résolu le SUTOM, ce n'est plus la peine !"
  hint_default = "[ESPACE] Jouer au SUTOM"
  _setup_overhead_camera()
  _setup_journal_surface()


func _can_try(player: Node) -> bool:
  var oscillo_solved: bool = player.state_machine[MachineOscillo.NAME] == Machine.StateMachine.SOLVED
  var pc_solved: bool = player.state_machine[MachineOrdinateur.NAME] == Machine.StateMachine.SOLVED
  return oscillo_solved and pc_solved


func _on_try_machine(player: Node, has_object: bool) -> void:
  _player_ref          = player
  player.in_minigame   = true
  player.minigame_name = NAME
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _begin_game(player.camera, has_object)
  if not game_finished.is_connected(_on_game_finished):
    game_finished.connect(_on_game_finished, CONNECT_ONE_SHOT)

# ── Caméra overhead ───────────────────────────────────────────────────────────

func _setup_overhead_camera() -> void:
  if has_node("OverheadCamera"):
    _overhead_cam = $OverheadCamera
    return
  _overhead_cam = Camera3D.new()
  _overhead_cam.name = "OverheadCamera"
  _overhead_cam.position = Vector3(0, camera_height, 0)
  _overhead_cam.rotation_degrees = Vector3(-90, 0, 0)
  _overhead_cam.current = false
  add_child(_overhead_cam)

# ── Surface journal avec SubViewport ─────────────────────────────────────────

func _setup_journal_surface() -> void:
  var mesh_node: MeshInstance3D = null
  for child in find_children("*", "MeshInstance3D", true, false):
    mesh_node = child as MeshInstance3D
    if mesh_node:
      break
  if mesh_node == null:
    return

  var base_mat := StandardMaterial3D.new()
  base_mat.albedo_color = Color(0.94, 0.92, 0.86)
  mesh_node.set_surface_override_material(0, base_mat)

  var aabb := mesh_node.get_aabb()
  _top_plane = MeshInstance3D.new()
  _top_plane.name = "JournalTop"
  var plane_mesh := PlaneMesh.new()
  plane_mesh.size = Vector2(aabb.size.x, aabb.size.z)
  _top_plane.mesh = plane_mesh
  _top_plane.position = Vector3(0.0, aabb.end.y + 0.001, 0.0)
  mesh_node.add_child(_top_plane)

  _vp = SubViewport.new()
  _vp.name = "SutomViewport"
  _vp.size = Vector2i(512, 724)
  _vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  _vp.transparent_bg = false
  add_child(_vp)

  _build_grid_ui()
  call_deferred("_apply_viewport_texture")

func _apply_viewport_texture() -> void:
  var mat := StandardMaterial3D.new()
  mat.albedo_texture = _vp.get_texture()
  _top_plane.set_surface_override_material(0, mat)

func _make_stylebox(color: Color, radius: int = 4, border: bool = false) -> StyleBoxFlat:
  var s := StyleBoxFlat.new()
  s.bg_color = color
  s.corner_radius_top_left     = radius
  s.corner_radius_top_right    = radius
  s.corner_radius_bottom_left  = radius
  s.corner_radius_bottom_right = radius
  if border:
    s.border_width_left   = 2
    s.border_width_right  = 2
    s.border_width_top    = 2
    s.border_width_bottom = 2
    s.border_color = Color(0.60, 0.57, 0.52)
  return s

func _build_grid_ui() -> void:
  const VW := 512
  const VH := 724
  const CELL := 52
  const GAP  := 6

  var bg := ColorRect.new()
  bg.set_anchors_preset(Control.PRESET_FULL_RECT)
  bg.color = COLOR_PAPER
  _vp.add_child(bg)

  var title := Label.new()
  title.text = "SUTOM"
  title.position = Vector2(0, 16)
  title.size = Vector2(VW, 36)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
  title.add_theme_font_size_override("font_size", 30)
  _vp.add_child(title)

  _hint_label = Label.new()
  _hint_label.text = ""
  _hint_label.position = Vector2(0, 56)
  _hint_label.size = Vector2(VW, 20)
  _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _hint_label.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
  _hint_label.add_theme_font_size_override("font_size", 12)
  _vp.add_child(_hint_label)

  var grid_w := WORD_LENGTH * CELL + (WORD_LENGTH - 1) * GAP
  var grid_h := MAX_ATTEMPTS * CELL + (MAX_ATTEMPTS - 1) * GAP
  var gx := int((VW - grid_w) / 2.0)
  var gy := 86

  _panels.clear()
  _labels.clear()

  for r in range(MAX_ATTEMPTS):
    var row_p: Array = []
    var row_l: Array = []
    for c in range(WORD_LENGTH):
      var cell := Panel.new()
      cell.position = Vector2(gx + c * (CELL + GAP), gy + r * (CELL + GAP))
      cell.size = Vector2(CELL, CELL)
      var style := _make_stylebox(COLOR_FIRST_COL if c == 0 else COLOR_CELL_IDLE, 4, c != 0)
      cell.add_theme_stylebox_override("panel", style)
      _vp.add_child(cell)

      var lbl := Label.new()
      lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
      lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
      lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
      lbl.add_theme_font_size_override("font_size", 22)
      lbl.add_theme_color_override("font_color", Color.BLACK)
      cell.add_child(lbl)

      row_p.append(cell)
      row_l.append(lbl)
    _panels.append(row_p)
    _labels.append(row_l)

  _result_label = Label.new()
  _result_label.position = Vector2(16, gy + grid_h + 10)
  _result_label.size = Vector2(VW - 32, 44)
  _result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _result_label.add_theme_font_size_override("font_size", 13)
  _result_label.visible = false
  _vp.add_child(_result_label)

  var instr := Label.new()
  instr.text = "Les lettres entourées d'un carré rouge sont bien placées.\nLes lettres entourées d'un cercle jaune sont mal placées\n(mais présentes dans le mot).\nLes lettres qui restent sur fond bleu ne sont pas dans le mot."
  instr.position = Vector2(16, VH - 114)
  instr.size = Vector2(VW - 32, 108)
  instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  instr.add_theme_color_override("font_color", Color(0.50, 0.47, 0.43))
  instr.add_theme_font_size_override("font_size", 14)
  _vp.add_child(instr)

# ── Interface publique (dispatcher player) ───────────────────────────────────

func _on_game_finished(won: bool) -> void:
  if _player_ref == null:
    return
  _on_try_machine_done(_player_ref, won)
  _player_ref.in_minigame   = false
  _player_ref.minigame_name = ""
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  if won:
    _player_ref.state_machine[machine_name] = Machine.StateMachine.SOLVED
    _player_ref.show_message(message_waiting_unlocked, 3.0)


# ── Entrée / sortie ───────────────────────────────────────────────────────────

func _begin_game(player_cam: Camera3D, has_object: bool) -> void:
  if _active:
    return
  _active = true
  _player_camera = player_cam
  _row = 0
  _col = 1
  _won = false

  # Remet la caméra à sa position locale cible avant de lire son global_transform
  _overhead_cam.position = Vector3(0, camera_height, 0)
  _overhead_cam.rotation_degrees = Vector3(-90, 0, 0)

  var words: Array = REAL_WORDS if has_object else FAKE_WORDS
  _target = words[randi() % words.size()].to_upper()

  for r in range(MAX_ATTEMPTS):
    for c in range(WORD_LENGTH):
      _labels[r][c].text = _target[0] if c == 0 else ""
      var style := _make_stylebox(COLOR_FIRST_COL if c == 0 else COLOR_CELL_IDLE, 4, c != 0)
      _panels[r][c].add_theme_stylebox_override("panel", style)

  _hint_label.text = "Mot de %d lettres  •  Commence par « %s »" % [WORD_LENGTH, _target[0]]
  _result_label.visible = false

  _transition_to_overhead()

func _close_game(won: bool) -> void:
  _active = false
  _close_won = won
  _transition_to_player()

# ── Transitions caméra ───────────────────────────────────────────────────────

func _transition_to_overhead() -> void:
  _cam_end_pos   = _overhead_cam.global_position
  _cam_end_basis = _overhead_cam.global_basis
  _cam_start_pos   = _player_camera.global_position
  _cam_start_basis = _player_camera.global_basis
  _overhead_cam.global_transform = _player_camera.global_transform
  _overhead_cam.make_current()
  var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
  tw.tween_method(_animate_cam, 0.0, 1.0, cam_transition_duration)

func _transition_to_player() -> void:
  _cam_start_pos   = _overhead_cam.global_position
  _cam_start_basis = _overhead_cam.global_basis
  _cam_end_pos   = _player_camera.global_position
  _cam_end_basis = _player_camera.global_basis
  var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
  tw.tween_method(_animate_cam, 0.0, 1.0, cam_transition_duration)
  tw.tween_callback(_on_return_done)

func _animate_cam(t: float) -> void:
  var mid := Vector3(
    (_cam_start_pos.x + _cam_end_pos.x) * 0.5,
    maxf(_cam_start_pos.y, _cam_end_pos.y) + cam_arc_height,
    (_cam_start_pos.z + _cam_end_pos.z) * 0.5
  )
  var u := 1.0 - t
  var pos := u * u * _cam_start_pos + 2.0 * u * t * mid + t * t * _cam_end_pos
  var rot := Quaternion(_cam_start_basis).slerp(Quaternion(_cam_end_basis), t)
  _overhead_cam.global_transform = Transform3D(Basis(rot), pos)

func _on_return_done() -> void:
  if _player_camera and is_instance_valid(_player_camera):
    _player_camera.make_current()
  game_finished.emit(_close_won)

# ── Saisie clavier ────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
  if not _active:
    return
  var is_right_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
  if is_right_click:
    get_viewport().set_input_as_handled()
    _close_game(_won)
    return
  if not (event is InputEventKey and event.pressed):
    return
  get_viewport().set_input_as_handled()
  var game_over := _won or _row >= MAX_ATTEMPTS
  match event.keycode:
    KEY_ESCAPE:
      _close_game(_won)
    KEY_ENTER, KEY_KP_ENTER:
      if game_over:
        _close_game(_won)
      else:
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
    _panels[_row][c].add_theme_stylebox_override("panel", _make_stylebox(colors[c], 4))
  var won := (guess == _target)
  _row += 1
  _col = 1
  if won:
    _won = true
    _result_label.text = "Bravo !  Le mot était « %s »." % _target
    _result_label.add_theme_color_override("font_color", Color(0.10, 0.45, 0.10))
    _result_label.visible = true
  elif _row >= MAX_ATTEMPTS:
    _result_label.text = "Perdu...  Le mot était « %s »." % _target
    _result_label.add_theme_color_override("font_color", Color(0.70, 0.15, 0.10))
    _result_label.visible = true

func _evaluate(guess: String) -> Array:
  var result := []
  result.resize(WORD_LENGTH)
  result.fill(COLOR_ABSENT)
  var remaining: Array = []
  for i in range(WORD_LENGTH):
    remaining.append(_target[i])
  for i in range(WORD_LENGTH):
    if guess[i] == _target[i]:
      result[i] = COLOR_CORRECT
      remaining[i] = ""
  for i in range(WORD_LENGTH):
    if result[i] == COLOR_CORRECT:
      continue
    var idx: int = remaining.find(guess[i])
    if idx != -1:
      result[i] = COLOR_PRESENT
      remaining[idx] = ""
  return result
