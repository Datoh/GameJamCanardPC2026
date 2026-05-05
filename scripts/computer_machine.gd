extends Machine
class_name MachineOrdinateur

const NAME := "Ordinateur"

const ENDPOINTS_KO = {
    "rouge": [Vector2i(6, 4), Vector2i(11, 15)],
    "vert":  [Vector2i(0, 7),  Vector2i(11, 7)],
    "bleu":  [Vector2i(6, 10),  Vector2i(10, 0)],
    "jaune": [Vector2i(2, 0), Vector2i(0, 8)],
  }

const ENDPOINTS_OK = {
    "rouge": [Vector2i(6, 4), Vector2i(11, 15)],
    "vert":  [Vector2i(0, 7),  Vector2i(11, 7)],
    "bleu":  [Vector2i(6, 10),  Vector2i(10, 0)],
    "jaune": [Vector2i(2, 1), Vector2i(3, 8)],
  }

# ── État jeu câbles ───────────────────────────────────────────────────────────
var endpoints:    Dictionary = {}
var chemins:      Dictionary = {}

var _en_dessin:   bool   = false
var _col_dessin:  String = ""
var _crt:         Array  = []   # Array[Vector2i] — chemin en cours

var peut_deplacer:  bool = false
var depl_restants:  int  = 2
var _drag_ep               # null | {"couleur": String, "idx": int}
var _drag_pos := Vector2.ZERO

# ── Caméra ────────────────────────────────────────────────────────────────────
@export var cam_distance:          float = 0.30
@export var cam_transition_duration: float = 1.0
@export var cam_arc_height:        float = 0.50

var _pc_cam:       Camera3D = null
var _player_camera: Camera3D = null
var _cam_start_pos   := Vector3.ZERO
var _cam_start_basis := Basis.IDENTITY
var _cam_end_pos     := Vector3.ZERO
var _cam_end_basis   := Basis.IDENTITY

# ── Viewport ──────────────────────────────────────────────────────────────────
var _vp:   SubViewport = null
var _grid: CableGrid   = null

# ── Interaction ───────────────────────────────────────────────────────────────
var _jeu_actif   := false
var _close_won   := false
var _player_ref: Node = null


func _ready() -> void:
  machine_name        = NAME
  dialogue_demande    = "ordinateur_demande"
  dialogue_resultat   = "ordinateur_resultat"
  robot_work_duration = 15.0
  message_idle               = "Ces câbles ne sont pas branchés. Je vais recabler tout ça."
  message_try_machine        = "Ces câbles se croisent, c'est insoluble comme ça. %s" % DialoguesData.robot_name + " pourrait peut-être s'y connaître en câblage."
  message_robot_working      = "Le %s" % DialoguesData.robot_name + " bidouille les câbles à l'arrière de la tour..."
  message_robot_done         = "Le %s" % DialoguesData.robot_name + " a l'air d'avoir terminé. Je devrais lui parler."
  message_try_machine_object = "Le %s" % DialoguesData.robot_name + " n'a pas réussi... Il m'a parlé d'un grand maître du cable management."
  message_solved             = "La tour est recablé."
  hint_default     = "[ESPACE] Regarder la tour"
  hint_try_machine = "[ESPACE] Rebrancher les câbles"
  hint_solved      = "[ESPACE] Tour réparé"
  input_ray_pickable = true
  input_event.connect(_on_circuit_input)
  _setup_viewport()
  _setup_pc_camera()
  _reinitialiser()


func _can_try(_player: Node) -> bool:
  return true

# ── Viewport + texture ────────────────────────────────────────────────────────

func _setup_viewport() -> void:
  _vp = SubViewport.new()
  _vp.name = "CableViewport"
  _vp.size = Vector2(CableGrid.VP_W, CableGrid.VP_H)
  _vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  _vp.transparent_bg = true
  add_child(_vp)

  _grid = CableGrid.new()
  _grid.size = Vector2(CableGrid.VP_W, CableGrid.VP_H)
  _vp.add_child(_grid)

  call_deferred("_apply_viewport_texture")


func _apply_viewport_texture() -> void:
  var src_mesh := %Circuit.mesh as PlaneMesh
  var overlay := MeshInstance3D.new()
  overlay.name = "CableOverlay"
  var plane := PlaneMesh.new()
  plane.size = src_mesh.size
  overlay.mesh = plane
  overlay.position = Vector3(0.0, 0.001, 0.0)  # légèrement devant (normale locale +Y)
  %Circuit.add_child(overlay)

  var mat := StandardMaterial3D.new()
  mat.albedo_texture = _vp.get_texture()
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  overlay.set_surface_override_material(0, mat)


# ── Caméra PC ─────────────────────────────────────────────────────────────────

func _setup_pc_camera() -> void:
  if has_node("PCCamera"):
    _pc_cam = $PCCamera
    return
  _pc_cam = Camera3D.new()
  _pc_cam.name = "PCCamera"
  _pc_cam.current = false
  add_child(_pc_cam)
  call_deferred("_place_pc_camera")


func _place_pc_camera() -> void:
  var normal: Vector3 = %Circuit.global_basis.y.normalized()
  _pc_cam.global_position = %Circuit.global_position + normal * cam_distance
  _pc_cam.look_at(%Circuit.global_position, Vector3.UP)


func _transition_to_pc(player_cam: Camera3D) -> void:
  _player_camera = player_cam
  # Recalcule la cible à chaque entrée (la caméra PC a pu bouger lors du retour précédent)
  var normal: Vector3 = %Circuit.global_basis.y.normalized()
  _pc_cam.global_position = %Circuit.global_position + normal * cam_distance
  _pc_cam.look_at(%Circuit.global_position, Vector3.UP)
  _cam_end_pos   = _pc_cam.global_position
  _cam_end_basis = _pc_cam.global_basis
  _cam_start_pos   = player_cam.global_position
  _cam_start_basis = player_cam.global_basis
  _pc_cam.global_transform = player_cam.global_transform
  _pc_cam.make_current()
  var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
  tw.tween_method(_animate_cam, 0.0, 1.0, cam_transition_duration)
  tw.tween_callback(func():
    _jeu_actif = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  )


func _transition_to_player() -> void:
  _cam_start_pos   = _pc_cam.global_position
  _cam_start_basis = _pc_cam.global_basis
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
  _pc_cam.global_transform = Transform3D(Basis(rot), pos)


func _on_return_done() -> void:
  if _player_camera and is_instance_valid(_player_camera):
    _player_camera.make_current()
  if _player_ref != null:
    _player_ref.in_minigame   = false
    _player_ref.minigame_name = ""
    _on_try_machine_done(_player_ref, _close_won)
  _close_won = false
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ── Logique jeu câbles ────────────────────────────────────────────────────────

func _reinitialiser(player: Node = null) -> void:
  var use_ok: bool = player != null and player.state_machine.get(MachineTV.NAME, 0) >= Machine.StateMachine.UNLOCKED
  endpoints = {}
  for c in CableGrid.NOMS:
    var src: Array = ENDPOINTS_OK[c] if use_ok else ENDPOINTS_KO[c]
    endpoints[c] = [src[0], src[1]]
  chemins = {}
  for c in CableGrid.NOMS:
    chemins[c] = []
  _en_dessin   = false
  _col_dessin  = ""
  _crt         = []
  _drag_ep     = null
  depl_restants = 2
  peut_deplacer = false
  _grid_update()


func debloquer_deplacement() -> void:
  peut_deplacer = true
  _grid_update()


func _grid_update() -> void:
  if _grid == null:
    return
  _grid.endpoints     = endpoints
  _grid.chemins       = chemins
  _grid.en_dessin     = _en_dessin
  _grid.col_dessin    = _col_dessin
  _grid.crt           = _crt
  _grid.drag_ep       = _drag_ep
  _grid.drag_pos      = _drag_pos
  _grid.peut_deplacer = peut_deplacer
  _grid.depl_restants = depl_restants
  _grid.queue_redraw()


# ── Conversion écran → SubViewport (intersection rayon-plan) ─────────────────

func _world_to_sv(world_pos: Vector3) -> Vector2:
  var local: Vector3 = %Circuit.to_local(world_pos)
  var mesh  := %Circuit.mesh as PlaneMesh
  var u := local.x / mesh.size.x + 0.5
  var v := local.z / mesh.size.y + 0.5
  return Vector2(u * CableGrid.VP_W, v * CableGrid.VP_H)


func _ray_to_sv(cam: Camera3D, screen_pos: Vector2) -> Vector2:
  var ray_o := cam.project_ray_origin(screen_pos)
  var ray_d := cam.project_ray_normal(screen_pos)
  var plane_n = %Circuit.global_basis.y.normalized()
  var plane_p = %Circuit.global_position
  var denom := ray_d.dot(plane_n)
  if absf(denom) < 0.0001:
    return Vector2(-1.0, -1.0)
  var t = (plane_p - ray_o).dot(plane_n) / denom
  if t < 0.0:
    return Vector2(-1.0, -1.0)
  return _world_to_sv(ray_o + ray_d * t)


# ── Entrée 3D ──────────────────────────────────────────────────────────────────

func _on_circuit_input(camera: Node, event: InputEvent, _world_pos: Vector3, _normal: Vector3, _shape: int) -> void:
  if not _jeu_actif:
    return
  var cam := camera as Camera3D
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    var sv := _ray_to_sv(cam, event.position)
    if sv.x < 0.0:
      return
    if event.pressed:
      _sur_press(sv)
    else:
      _sur_release(sv)
  elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
    var sv := _ray_to_sv(cam, event.position)
    if sv.x < 0.0:
      return
    _drag_pos = sv
    if _drag_ep != null:
      _grid_update()
    elif _en_dessin:
      var cell := _pos_to_cell(sv)
      if _valide(cell):
        _etendre(cell)


func _unhandled_input(event: InputEvent) -> void:
  if not _jeu_actif:
    return
  # Capture le relâchement souris même si hors du mesh
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
    if _en_dessin:
      _valider()
    elif _drag_ep != null:
      _drag_ep = null
      _grid_update()
  # Échap ou clic droit quitte le mini-jeu
  var quit: bool = (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) \
           or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
  if quit:
    get_viewport().set_input_as_handled()
    _quitter_jeu()


# ── Logique de routage ─────────────────────────

func _pos_to_cell(pos: Vector2) -> Vector2i:
  return Vector2i(
    int((pos.x - CableGrid.MARGE) / CableGrid.TAILLE_CELL),
    int((pos.y - CableGrid.MARGE) / CableGrid.TAILLE_CELL)
  )

func _valide(c: Vector2i) -> bool:
  return c.x >= 0 and c.x < CableGrid.GRILLE_W and c.y >= 0 and c.y < CableGrid.GRILLE_H

func _ep_sur(cell: Vector2i) -> Dictionary:
  for c in CableGrid.NOMS:
    for i in 2:
      if endpoints[c][i] == cell:
        return {"couleur": c, "idx": i}
  return {}

func _cible_de(couleur: String, depart: Vector2i) -> Vector2i:
  return endpoints[couleur][1] if endpoints[couleur][0] == depart else endpoints[couleur][0]

func _occupe_par_autre(cell: Vector2i, col_exclue: String) -> bool:
  for c in CableGrid.NOMS:
    if c == col_exclue:
      continue
    if chemins[c].has(cell):
      return true
    if endpoints[c][0] == cell or endpoints[c][1] == cell:
      return true
  return false


func _sur_press(sv: Vector2) -> void:
  var cell := _pos_to_cell(sv)
  if not _valide(cell):
    return
  var ep := _ep_sur(cell)
  if ep.is_empty():
    return
  if peut_deplacer and depl_restants > 0:
    _drag_ep  = ep
    _drag_pos = sv
    _grid_update()
    return
  _commencer(ep["couleur"], cell)


func _commencer(col: String, depart: Vector2i) -> void:
  chemins[col] = []
  _en_dessin   = true
  _col_dessin  = col
  _crt         = [depart]
  _grid_update()


func _etendre(cell: Vector2i) -> void:
  if _crt.is_empty():
    return
  var last := _crt.back() as Vector2i
  if cell == last:
    return
  var d := (cell - last).abs()
  if d.x + d.y != 1:
    return
  var idx := _crt.find(cell)
  if idx >= 0:
    _crt.resize(idx + 1)
    _grid_update()
    return
  if _occupe_par_autre(cell, _col_dessin):
    return
  _crt.append(cell)
  AudioManager.play(AudioData.AUDIO_CABLE, global_position)
  if cell == _cible_de(_col_dessin, _crt[0]):
    _valider()
    return
  _grid_update()


func _sur_release(sv: Vector2) -> void:
  if _drag_ep != null:
    _deposer(_pos_to_cell(sv))
    _drag_ep = null
    _grid_update()
    return
  if _en_dessin:
    _valider()


func _valider() -> void:
  _en_dessin = false
  if _crt.size() < 2:
    _crt = []
    _grid_update()
    return
  var debut := _crt[0] as Vector2i
  var fin   := _crt.back() as Vector2i
  if fin == _cible_de(_col_dessin, debut):
    chemins[_col_dessin] = _crt.duplicate()
    _crt = []
    _grid_update()
    AudioManager.play(AudioData.AUDIO_CABLE_VALIDATE, global_position)
    _check_victoire()
  else:
    _crt = []
    _grid_update()


func _deposer(cell: Vector2i) -> void:
  if not _valide(cell):
    return
  var c   := _drag_ep["couleur"] as String
  var idx := _drag_ep["idx"] as int
  for other in CableGrid.NOMS:
    for i in 2:
      if other == c and i == idx:
        continue
      if endpoints[other][i] == cell:
        return
  endpoints[c][idx] = cell
  chemins[c]    = []
  depl_restants -= 1


func _check_victoire() -> void:
  for c in CableGrid.NOMS:
    var path = chemins[c]
    if path.size() < 2:
      return
    var ep0 := endpoints[c][0] as Vector2i
    var ep1 := endpoints[c][1] as Vector2i
    var a   := path[0] as Vector2i
    var b   := path.back() as Vector2i
    if not ((a == ep0 and b == ep1) or (a == ep1 and b == ep0)):
      return
  _on_victoire()


func _on_victoire() -> void:
  AudioManager.play(AudioData.AUDIO_CABLE_VALIDATE_ALL, global_position)
  _close_won = true
  _quitter_jeu()
  if _player_ref == null:
    return
  _player_ref.state_machine[NAME] = Machine.StateMachine.SOLVED


# ── Lancer / quitter le mini-jeu ─────────────────────────────────────────────

func _demarrer_jeu(player: Node) -> void:
  _player_ref = player
  player.in_minigame   = true
  player.minigame_name = NAME
  _reinitialiser(player)
  _transition_to_pc(player.camera)


func _quitter_jeu() -> void:
  if not _close_won:
    AudioManager.play(AudioData.AUDIO_CABLE_ERROR, global_position)
  _jeu_actif = false
  _en_dessin = false
  _drag_ep   = null
  _crt       = []
  _grid_update()
  _transition_to_player()


# ── Override Machine ──────────────────────────────────────────────────────────

func is_dialogue_locked(dialogue_id: String, player: Node) -> bool:
  if dialogue_id == "ordinateur_dlss5":
    return player.state_machine.get(NAME, 0) != Machine.StateMachine.SOLVED
  return super.is_dialogue_locked(dialogue_id, player)


func _on_try_machine(player: Node, _has_object: bool) -> void:
  if _jeu_actif:
    return
  _demarrer_jeu(player)
