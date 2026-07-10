class_name MachineOscillo
extends Machine

signal power_cut()

const NAME := "Oscillo"

# ── Signal math ───────────────────────────────────────────────────────────────
# Niveaux : nb de courbes actives, phase réglable ou non, cibles [A, F, φ]
const LEVELS: Array[Dictionary] = [
  {"curves": 1, "use_phase": false, "targets": [[5, 3, 0]]},
  {"curves": 2, "use_phase": false, "targets": [[5, 3, 0], [2, 9, 0]]},
]
const MATCH_TOL  := 0.8
const SAMPLE_CNT := 200

@export var cam_distance:            float = 0.45
@export var cam_transition_duration: float = 1.0
@export var cam_arc_height:          float = 0.50
@export var _audio_stream: AudioStreamPlayer3D = null

# ── État ──────────────────────────────────────────────────────────────────────
var amplitudes:  Array[int] = [3, 5]
var frequencies: Array[int] = [1, 5]
var phases:      Array[int] = [0, 0]

var _level: int = 0

var _params: Array[Dictionary] = []

# ── Viewports ────────────────────────────────────────────────────────────────
var _curves_vp:      SubViewport          = null
var _curves_display: OscilloCurvesDisplay = null

# ── Caméra ────────────────────────────────────────────────────────────────────
var _cam:            Camera3D = null
var _player_camera:  Camera3D = null
var _cam_start_pos   := Vector3.ZERO
var _cam_start_basis := Basis.IDENTITY
var _cam_end_pos     := Vector3.ZERO
var _cam_end_basis   := Basis.IDENTITY

# ── État mini-jeu ─────────────────────────────────────────────────────────────
var power_cut_available: bool = false

var _jeu_actif:        bool = false
var _close_won:        bool = false
var _victory_pending:  bool = false
var _controls_enabled: bool = false

# ── Meshes (noms uniques à définir dans la scène) ─────────────────────────────
@onready var _courbes:     MeshInstance3D = %Courbes
@onready var _courbe_a_1:  MeshInstance3D = %CourbeA1
@onready var _courbe_f_1:  MeshInstance3D = %CourbeF1
@onready var _courbe_p_1:  MeshInstance3D = %CourbeP1
@onready var _courbe_a_2:  MeshInstance3D = %CourbeA2
@onready var _courbe_f_2:  MeshInstance3D = %CourbeF2
@onready var _courbe_p_2:  MeshInstance3D = %CourbeP2
@onready var _box_oscillo: MeshInstance3D = %BoxOscillo


func _ready() -> void:
  machine_name        = NAME
  message_idle        = tr("msgOscilloIdle")
  message_solved      = tr("msgSignalReproduced")
  hint_default        = tr("hintLookOscillo")
  hint_solved         = tr("hintOscilloCalibrated")
  input_ray_pickable  = true
  input_event.connect(_on_machine_input)
  call_deferred("_setup_all")


func interact() -> void:
  if power_cut_available and GameData.state(machine_name) == StateMachine.SOLVED:
    power_cut_available = false
    GameData.show_message(tr("msgPowerCut") % [DialoguesData.robot_name], 5.0)
    power_cut.emit()
    return
  super.interact()


func _can_try() -> bool:
  return true


func is_dialogue_locked(dialogue_id: String) -> bool:
  if dialogue_id == "cafetiere_existentiel":
    return GameData.state(NAME) != StateMachine.SOLVED
  return super.is_dialogue_locked(dialogue_id)


func get_interaction_hint() -> String:
  match GameData.state(machine_name):
    StateMachine.SOLVED:
      if power_cut_available:
        return tr("hintCutPower")
      return tr("hintOscilloCalibrated")
    _:
      return hint_default


func _on_try_machine(_has_object: bool) -> void:
  _controls_enabled = true
  _demarrer_jeu()


# ── Setup ─────────────────────────────────────────────────────────────────────

func _setup_all() -> void:
  _setup_curves()
  _setup_params()
  _setup_camera()
  _apply_level()
  _update_displays()


func _setup_curves() -> void:
  _curves_vp = SubViewport.new()
  _curves_vp.size = Vector2i(OscilloCurvesDisplay.VP_W, OscilloCurvesDisplay.VP_H)
  _curves_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  _curves_vp.transparent_bg = false
  add_child(_curves_vp)

  _curves_display = OscilloCurvesDisplay.new()
  _curves_display.size = Vector2(OscilloCurvesDisplay.VP_W, OscilloCurvesDisplay.VP_H)
  _curves_vp.add_child(_curves_display)

  _apply_vp_to_mesh(_curves_vp, _courbes)


func _setup_params() -> void:
  const CURVE_COLORS: Array[Color] = [Color(0.9, 0.3, 0.3), Color(0.3, 0.9, 0.3)]
  var defs := [
    {"mesh": _courbe_a_1, "curve": 0, "type": "a"},
    {"mesh": _courbe_f_1, "curve": 0, "type": "f"},
    {"mesh": _courbe_p_1, "curve": 0, "type": "p"},
    {"mesh": _courbe_a_2, "curve": 1, "type": "a"},
    {"mesh": _courbe_f_2, "curve": 1, "type": "f"},
    {"mesh": _courbe_p_2, "curve": 1, "type": "p"},
  ]
  for d in defs:
    var vp := SubViewport.new()
    vp.size = Vector2i(OscilloParamDisplay.VP_W, OscilloParamDisplay.VP_H)
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.transparent_bg = false
    add_child(vp)

    var disp := OscilloParamDisplay.new()
    disp.size = Vector2(OscilloParamDisplay.VP_W, OscilloParamDisplay.VP_H)
    disp.curve_color = CURVE_COLORS[d["curve"]]
    vp.add_child(disp)

    _apply_vp_to_mesh(vp, d["mesh"])

    _params.append({
      "mesh":    d["mesh"],
      "display": disp,
      "curve":   d["curve"],
      "type":    d["type"],
    })


func _apply_vp_to_mesh(vp: SubViewport, mesh_inst: MeshInstance3D) -> void:
  var mat := StandardMaterial3D.new()
  mat.albedo_texture = vp.get_texture()
  mat.shading_mode   = BaseMaterial3D.SHADING_MODE_UNSHADED
  mesh_inst.set_surface_override_material(0, mat)


# ── Caméra ────────────────────────────────────────────────────────────────────

func _setup_camera() -> void:
  if has_node("OscilloCam2"):
    _cam = $OscilloCam2
    return
  _cam = Camera3D.new()
  _cam.name = "OscilloCam2"
  _cam.current = false
  add_child(_cam)
  _place_camera()


func _place_camera() -> void:
  var normal := _box_oscillo.global_basis.y.normalized()
  _cam.global_position = _box_oscillo.global_position + normal * cam_distance
  _cam.look_at(_box_oscillo.global_position, Vector3.UP)


func _transition_to_screen(player_cam: Camera3D) -> void:
  _player_camera = player_cam
  _place_camera()
  _cam_end_pos   = _cam.global_position
  _cam_end_basis = _cam.global_basis
  _cam_start_pos   = player_cam.global_position
  _cam_start_basis = player_cam.global_basis
  _cam.global_transform = player_cam.global_transform
  _cam.make_current()
  var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
  tw.tween_method(_animate_cam, 0.0, 1.0, cam_transition_duration)
  tw.tween_callback(func():
    _jeu_actif = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  )


func _transition_to_player() -> void:
  _cam_start_pos   = _cam.global_position
  _cam_start_basis = _cam.global_basis
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
  _cam.global_transform = Transform3D(Basis(rot), pos)


func _on_return_done() -> void:
  GameData.minigame_name = ""
  if _player_camera and is_instance_valid(_player_camera):
    _player_camera.make_current()
  if GameData.player != null:
    _on_try_machine_done(_close_won)
  _close_won = false
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ── Raycasting vers un mesh ───────────────────────────────────────────────────

func _ray_to_mesh_uv(cam: Camera3D, screen_pos: Vector2, mesh_inst: MeshInstance3D) -> Vector2:
  var ray_o := cam.project_ray_origin(screen_pos)
  var ray_d := cam.project_ray_normal(screen_pos)
  var plane_n := mesh_inst.global_basis.y.normalized()
  var plane_p := mesh_inst.global_position
  var denom   := ray_d.dot(plane_n)
  if absf(denom) < 0.0001:
    return Vector2(-1.0, -1.0)
  var t := (plane_p - ray_o).dot(plane_n) / denom
  if t < 0.0:
    return Vector2(-1.0, -1.0)
  var hit   := ray_o + ray_d * t
  var local := mesh_inst.to_local(hit)
  var pm    := mesh_inst.mesh as PlaneMesh
  if absf(local.x) > pm.size.x * 0.5 or absf(local.z) > pm.size.y * 0.5:
    return Vector2(-1.0, -1.0)
  return Vector2(local.x / pm.size.x + 0.5, local.z / pm.size.y + 0.5)


# ── Entrée ────────────────────────────────────────────────────────────────────

func _on_machine_input(_camera: Node, _event: InputEvent, _world_pos: Vector3, _normal: Vector3, _shape: int) -> void:
  pass


func _unhandled_input(event: InputEvent) -> void:
  if not _jeu_actif:
    return
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
    get_viewport().set_input_as_handled()
    var screen_pos := get_viewport().get_mouse_position()
    for i in _params.size():
      var p    := _params[i]
      var mesh := p["mesh"] as MeshInstance3D
      if not mesh.visible:
        continue
      var uv   := _ray_to_mesh_uv(_cam, screen_pos, mesh)
      if uv.x < 0.0:
        continue
      var disp  := p["display"] as OscilloParamDisplay
      var delta := disp.on_click(uv)
      if delta != 0:
        _apply_delta(i, delta)
        return
  var quit: bool = (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) \
       or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
  if quit:
    get_viewport().set_input_as_handled()
    _quitter_jeu()


# ── Logique mini-jeu ──────────────────────────────────────────────────────────

func _demarrer_jeu() -> void:
  GameData.minigame_name = NAME
  _victory_pending     = false
  _update_displays()
  _transition_to_screen(GameData.player.camera)


func _sinusoid(a: int, f: int, p: int, x: float) -> float:
  return a * sin(f * x + p * PI / 10.0)


func _target_at(x: float) -> float:
  var total := 0.0
  for tgt in LEVELS[_level]["targets"]:
    total += _sinusoid(tgt[0], tgt[1], tgt[2], x)
  return total


func _is_match() -> bool:
  var curve_count: int = LEVELS[_level]["curves"]
  var max_d := 0.0
  for i in SAMPLE_CNT:
    var x      := TAU * float(i) / float(SAMPLE_CNT)
    var player := 0.0
    for c in curve_count:
      player += _sinusoid(amplitudes[c], frequencies[c], phases[c], x)
    max_d = maxf(max_d, abs(_target_at(x) - player))
  return max_d < MATCH_TOL


func _apply_level() -> void:
  var lvl: Dictionary = LEVELS[_level]
  var curve_count: int = lvl["curves"]
  var use_phase: bool = lvl["use_phase"]
  _courbe_a_2.visible = curve_count >= 2
  _courbe_f_2.visible = curve_count >= 2
  _courbe_p_1.visible = use_phase
  _courbe_p_2.visible = use_phase and curve_count >= 2
  _curves_display.targets     = lvl["targets"]
  _curves_display.curve_count = curve_count
  _curves_display.title       = tr("oscilloLevelTitle") % [_level + 1, LEVELS.size()]


func _reset_player_params() -> void:
  amplitudes  = [3, 2]
  frequencies = [1, 5]
  phases      = [0, 0]


func _apply_delta(param_idx: int, delta: int) -> void:
  if _victory_pending:
    return
  var p     := _params[param_idx]
  var curve: int = p["curve"]
  match p["type"]:
    "a": amplitudes[curve]  = clampi(amplitudes[curve]  + delta, 1, 10)
    "f": frequencies[curve] = clampi(frequencies[curve] + delta, 1, 20)
    "p": phases[curve]      = clampi(phases[curve]      + delta, 0, 10)
  match p["type"]:
    "a": AudioManager.play(AudioData.AUDIO_OSCILLO_BEEP_1 if delta > 0 else AudioData.AUDIO_OSCILLO_BEEP_2, global_position)
    "f": AudioManager.play(AudioData.AUDIO_OSCILLO_BEEP_3 if delta > 0 else AudioData.AUDIO_OSCILLO_BEEP_4, global_position)
    "p": AudioManager.play(AudioData.AUDIO_OSCILLO_BEEP_1 if delta > 0 else AudioData.AUDIO_OSCILLO_BEEP_2, global_position)
  _update_displays()
  if _is_match():
    _victory_pending = true
    get_tree().create_timer(0.8).timeout.connect(_on_level_done, CONNECT_ONE_SHOT)


func _update_displays() -> void:
  _curves_display.amplitudes  = amplitudes
  _curves_display.frequencies = frequencies
  _curves_display.phases      = phases
  _curves_display.queue_redraw()
  for p in _params:
    var disp  := p["display"] as OscilloParamDisplay
    var curve: int = p["curve"]
    match p["type"]:
      "a": disp.value = amplitudes[curve]
      "f": disp.value = frequencies[curve]
      "p": disp.value = phases[curve]
    disp.queue_redraw()


func _on_level_done() -> void:
  if not _jeu_actif:
    return
  _victory_pending = false
  if _level < LEVELS.size() - 1:
    _level += 1
    _reset_player_params()
    _apply_level()
    _update_displays()
    AudioManager.play(AudioData.AUDIO_OSCILLO_WIN, global_position)
    GameData.show_message(tr("msgOscilloLevelUp") % [_level + 1, LEVELS.size()], 3.0)
  else:
    _on_victoire()


func _on_victoire() -> void:
  if not _jeu_actif:
    return
  _close_won = true
  AudioManager.play(AudioData.AUDIO_OSCILLO_WIN, global_position)
  if _audio_stream:
    _audio_stream.stop()
  GameData.set_state(NAME, Machine.StateMachine.SOLVED)
  if GameData.player != null:
    GameData.show_message(tr("msgOscilloCalibrated"), 3.0)
  machine_done.emit(self)
  _quitter_jeu()


func _quitter_jeu() -> void:
  _jeu_actif       = false
  _victory_pending = false
  _transition_to_player()
