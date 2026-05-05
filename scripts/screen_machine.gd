extends Machine
class_name ScreenMachine

const NAME  := "Screen"
const DEBUG := false

@onready var _mouse_on_screen: Node3D = %MouseOnScreen
@onready var _computer_old_monitor: MeshInstance3D = %Computer_Old_Monitor
@onready var _computer_screen_plane: MeshInstance3D = %ComputerScreenPlane

@export var cam_distance:            float = 0.3
@export var cam_transition_duration: float = 1.0
@export var cam_arc_height:          float = 0.40

@export var _audio_stream: AudioStreamPlayer3D = null

var _black_mat: StandardMaterial3D = null

# ── Caméra ────────────────────────────────────────────────────────────────────
var _cam:            Camera3D = null
var _player_camera:  Camera3D = null
var _cam_start_pos   := Vector3.ZERO
var _cam_start_basis := Basis.IDENTITY
var _cam_end_pos     := Vector3.ZERO
var _cam_end_basis   := Basis.IDENTITY

# ── Mini-jeu article ──────────────────────────────────────────────────────────
var _jeu_actif:     bool = false
var _article_phase: int  = 0   # 0 = lecture mauvais, 1 = frappe, 2 = terminé
var _typed_count:   int  = 0
var _player_ref:    Node = null
var _article_layer: CanvasLayer     = null
var _article_ui:    ArticleTypingUI = null

const _AUDIO_PAUSE_DELAY := 0.35
var _audio_pause_timer: float = 0.0


func _ready() -> void:
  machine_name        = NAME
  dialogue_demande    = "article_demande"
  dialogue_resultat   = "article_resultat"
  robot_work_duration = 6.0
  _black_mat = StandardMaterial3D.new()
  _black_mat.albedo_color = Color.BLACK
  _black_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  _computer_old_monitor.set_surface_override_material(1, _black_mat)
  call_deferred("_setup_camera")


func _update_monitor(oscillo_solved: bool, pc_solved: bool) -> void:
  if _jeu_actif:
    return
  var mat = null if (oscillo_solved and pc_solved) else _black_mat
  _computer_old_monitor.set_surface_override_material(1, mat)


func _is_fully_repaired(player: Node) -> bool:
  return player.state_machine.get(MachineOscillo.NAME, 0) == Machine.StateMachine.SOLVED \
    and player.state_machine.get(MachineOrdinateur.NAME, 0) == Machine.StateMachine.SOLVED \
    and player.state_machine.get(MachineMaze.NAME, 0) == Machine.StateMachine.SOLVED \
    and player.state_machine.get(MachineSutom.NAME, 0) == Machine.StateMachine.SOLVED \
    and _mouse_on_screen.visible


func is_dialogue_locked(dialogue_id: String, player: Node) -> bool:
  if dialogue_id in ["article_demande", "article_resultat"]:
    if not _is_fully_repaired(player):
      return true
  return super.is_dialogue_locked(dialogue_id, player)


func interact(player: Node) -> void:
  if DEBUG:
    var state : Machine.StateMachine = player.state_machine.get(NAME, Machine.StateMachine.IDLE)
    if state == Machine.StateMachine.SOLVED:
      player.show_message("L'article est publié.", 3.0)
    elif not _jeu_actif:
      player.state_machine[NAME] = Machine.StateMachine.TRY_MACHINE_OBJECT
      _open_article(player)
    return

  var oscillo_solved: bool = player.state_machine.get(MachineOscillo.NAME, 0) == Machine.StateMachine.SOLVED
  var pc_solved: bool      = player.state_machine.get(MachineOrdinateur.NAME, 0) == Machine.StateMachine.SOLVED
  _update_monitor(oscillo_solved, pc_solved)
  var maze_solved: bool  = player.state_machine.get(MachineMaze.NAME, 0) == Machine.StateMachine.SOLVED
  var sutom_solved: bool = player.state_machine.get(MachineSutom.NAME, 0) == Machine.StateMachine.SOLVED

  if not oscillo_solved and not pc_solved:
    player.show_message("L'écran n'est pas alimenté, encore le différentiel qui à sauté. En plus la tour est mal branchée.", 3.0)
    return
  elif not oscillo_solved:
    player.show_message("L'écran n'est pas alimenté, encore le différentiel qui à sauté.", 3.0)
    return
  elif not pc_solved:
    player.show_message("La tour est mal branchée.", 3.0)
    return
  elif not maze_solved:
    player.show_message("Pas de souris...", 3.0)
    return
  elif not _mouse_on_screen.visible:
    player.show_message("Voilà une souris !", 3.0)
    _mouse_on_screen.visible = true
    return
  elif not sutom_solved:
    player.show_message("Il me demande un mot de passe mais je ne le connais pas.", 3.0)
    return

  var screen_state: Machine.StateMachine = player.state_machine.get(NAME, Machine.StateMachine.IDLE)
  match screen_state:
    Machine.StateMachine.IDLE:
      player.show_message("L'écran fonctionne ! Je pourrais demander à %s" % DialoguesData.robot_name + " de rédiger le test.", 4.0)
      player.state_machine[NAME] = Machine.StateMachine.TRY_MACHINE
    Machine.StateMachine.TRY_MACHINE:
      player.show_message("Je devrais parler à %s" % DialoguesData.robot_name + ".", 3.0)
    Machine.StateMachine.ROBOT_WORKING:
      player.show_message("%s" % DialoguesData.robot_name + " est en train de rédiger l'article...", 3.0)
    Machine.StateMachine.ROBOT_DONE:
      player.show_message("%s" % DialoguesData.robot_name + " a l'air d'avoir terminé. Je devrais lui parler.", 3.0)
    Machine.StateMachine.TRY_MACHINE_OBJECT:
      _open_article(player)
    _:
      player.show_message("L'article est publié.", 3.0)


# ── Mini-jeu article ──────────────────────────────────────────────────────────

const _ARTICLE_SCENE := preload("res://scenes/article_typing_ui.tscn")

func _open_article(player: Node) -> void:
  _player_ref    = player
  _article_phase = 0
  _typed_count   = 0

  _article_layer = CanvasLayer.new()
  add_child(_article_layer)

  _article_ui = _ARTICLE_SCENE.instantiate()
  _article_layer.add_child(_article_ui)

  _article_ui.show_bad_article()

  player.in_minigame = true
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  set_deferred("_jeu_actif", true)


func _process(delta: float) -> void:
  if _audio_pause_timer > 0.0:
    _audio_pause_timer -= delta
    if _audio_pause_timer <= 0.0 and _audio_stream != null and _audio_stream.playing:
      _audio_stream.stream_paused = true


func _finish_article() -> void:
  _jeu_actif = false
  if _player_ref != null:
    _player_ref.state_machine[NAME] = Machine.StateMachine.SOLVED
    _player_ref.in_minigame = false
  if _article_layer != null:
    _article_layer.queue_free()
    _article_layer = null
    _article_ui    = null
  if _audio_stream != null:
    _audio_stream.stop()
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
  if not _jeu_actif:
    return

  if _article_phase == 2:
    var escape     :bool = event is InputEventKey         and event.pressed and event.keycode == KEY_ESCAPE
    var right_click:bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
    if escape or right_click:
      get_viewport().set_input_as_handled()
      _finish_article()
    return

  if not (event is InputEventKey and event.pressed and not event.echo):
    return

  get_viewport().set_input_as_handled()

  match _article_phase:
    0:
      _article_phase = 1
      _typed_count   = 0
      _article_ui.show_typing("", false)
    1:
      if _audio_stream != null:
        if not _audio_stream.playing:
          _audio_stream.play()
        else:
          _audio_stream.stream_paused = false
        _audio_pause_timer = _AUDIO_PAUSE_DELAY
      _typed_count = mini(_typed_count + randi_range(2, 6), _article_ui.PLAYER_ARTICLE.length())
      var done := _typed_count >= _article_ui.PLAYER_ARTICLE.length()
      _article_ui.show_typing(_article_ui.PLAYER_ARTICLE.substr(0, _typed_count), done)
      if done:
        _article_phase = 2


# ── Caméra ────────────────────────────────────────────────────────────────────

func _setup_camera() -> void:
  if has_node("ScreenCam"):
    _cam = $ScreenCam
    return
  _cam = Camera3D.new()
  _cam.name = "ScreenCam"
  _cam.current = false
  add_child(_cam)
  _place_camera()


func _place_camera() -> void:
  var normal := _computer_screen_plane.global_basis.y.normalized()
  _cam.global_position = _computer_screen_plane.global_position + normal * cam_distance
  _cam.look_at(_computer_screen_plane.global_position, Vector3.UP)


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
  tw.tween_callback(func(): if _player_camera: _player_camera.make_current())


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
