extends StaticBody3D

signal captcha_done(success: bool)

const LAPIN_DIR   := "res://assets/textures/tv/lapin/"
const LAPIN_FILES := [
  "lapin1.png", "lapin2.png", "lapin3.png",
  "lapin4.png", "lapin5.png", "lapin6.png", "lapain.png"
]

const COLOR_LAPIN := [Color.PALE_GOLDENROD,  Color.BISQUE, Color.CYAN, Color.GREEN_YELLOW, Color.LIGHT_SEA_GREEN]

@export var _tv_title: TextureRect = null
@export var _video_player: VideoStreamPlayer = null
@onready var _captcha_ui: Control = %TVCaptcha

var _cell_rects:    Array = []
var _pink_indices:  Array = []

var _player_ref:    Node      = null
var _captcha_active: bool     = false
var _cell_selected: Array     = []
var _cell_overlays: Array     = []
var _cell_rect_validate: Control = null


func _ready() -> void:
  add_to_group("machine")
  input_ray_pickable = true
  input_event.connect(_on_tv_input)
  _setup_captcha_scene()
  show_tv_title()


# ── Setup scène CAPTCHA ───────────────────────────────────────────────────────

func _setup_captcha_scene() -> void:
  _cell_rects.clear()
  _cell_overlays.clear()
  for i in 6:
    _cell_rects.append(_captcha_ui.get_node("Cell%d" % i))
    _cell_overlays.append(_captcha_ui.get_node("Overlay%d" % i))
  _cell_rect_validate = _captcha_ui.get_node("ValiderBG")


# ── Chargement des images ─────────────────────────────────────────────────────

func _apply_images_to_visual(has_feutres: bool) -> void:
  var pool := LAPIN_FILES.duplicate()
  pool.shuffle()
  pool = pool.slice(0, 6)
  _pink_indices = [0, 1, 2, 3, 4, 5]
  _pink_indices.shuffle()
  _pink_indices = _pink_indices.slice(0, 3)
  for i in 6:
    var tex := load(LAPIN_DIR + pool[i]) as Texture2D
    _cell_rects[i].texture  = tex
    if not has_feutres:
      _cell_rects[i].modulate = Color.BLACK
    else:
      _cell_rects[i].modulate = Color.HOT_PINK if _pink_indices.has(i) else COLOR_LAPIN.pick_random()


# ── États de la TV ────────────────────────────────────────────────────────────

func show_tv_title() -> void:
  _tv_title.visible     = true
  _captcha_ui.visible   = false
  _video_player.visible = false


func show_captcha(player: Node, has_feutres: bool) -> void:
  _tv_title.visible     = false
  _captcha_ui.visible   = true
  _video_player.visible = false
  _apply_images_to_visual(has_feutres)
  interact(player)


func show_video() -> void:
  _tv_title.visible     = false
  _captcha_ui.visible   = false
  _video_player.visible = true
  if not _video_player.is_playing():
    _video_player.play()


# ── Interface publique (dispatcher player) ───────────────────────────────────

func interact(player: Node) -> void:
  _player_ref = player
  match player.state_tele:
    player.TeleState.IDLE:
      if player.state_pc == player.PCState.IDLE:
        player._show_message("Vous essayez d'arrêter YouPub.", 3.0)
      else:
        player.state_tele = player.TeleState.CAPTCHA_PENDING
        player.puzzle_attempted["Feutres"] = true
        show_captcha(player, "Feutres" in player.inventory)
        player._show_message("Un CAPTCHA ? Il faut prouver que je ne suis pas un robot.", 3.0)
    player.TeleState.CAPTCHA_PENDING:
      if player._in_minigame:
        return
      _start_captcha(player)
      if not captcha_done.is_connected(_on_captcha_result):
        captcha_done.connect(_on_captcha_result, CONNECT_ONE_SHOT)
    player.TeleState.CAPTCHA_SOLVED, player.TeleState.VIDEO_WATCHED:
      show_video()


func get_interaction_hint(player: Node) -> String:
  match player.state_tele:
    player.TeleState.CAPTCHA_PENDING: return "[E] Résoudre le CAPTCHA"
    player.TeleState.CAPTCHA_SOLVED, player.TeleState.VIDEO_WATCHED: return "[E] Regarder la vidéo"
    _: return "[E] Regarder la télé"


func _on_captcha_result(success: bool) -> void:
  if _player_ref == null:
    return
  _player_ref._in_minigame = false
  if success:
    _player_ref.state_tele = _player_ref.TeleState.CAPTCHA_SOLVED
    show_video()


# ── Interaction souris CAPTCHA ────────────────────────────────────────────────

func _world_to_sv(world_pos: Vector3) -> Vector2:
  var local := to_local(world_pos)
  var shape  := $CollisionShape3D.shape as BoxShape3D
  var hx     := shape.size.x * 0.5
  var hy     := shape.size.y * 0.5
  var u      := (local.x + hx) / shape.size.x
  var v      := 1.0 - (local.y + hy) / shape.size.y
  return Vector2(u * 1920.0, v * 1080.0)


func _on_tv_input(_camera: Node, event: InputEvent, input_position: Vector3, _normal: Vector3, _shape: int) -> void:
  if not _captcha_active:
    return
  if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
    return
  var sv := _world_to_sv(input_position)
  if Rect2(_cell_rect_validate.position, _cell_rect_validate.size).has_point(sv):
    _validate_captcha()
    return
  for i in _cell_rects.size():
    var cell: Control = _cell_rects[i]
    if Rect2(cell.position, cell.size).has_point(sv):
      _cell_selected[i] = not _cell_selected[i]
      _update_selection_display()
      return


func _start_captcha(player: Node) -> void:
  var has_feutres: bool = "Feutres" in _player_ref.inventory
  _apply_images_to_visual(has_feutres)
  _player_ref     = player
  _captcha_active = true
  _cell_selected  = []
  _cell_selected.resize(6)
  _cell_selected.fill(false)
  player._in_minigame = true
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _update_selection_display()


func _update_selection_display() -> void:
  for i in 6:
    _cell_overlays[i].color.a = 0.45 if _cell_selected[i] else 0.0


func _validate_captcha() -> void:
  var has_feutres: bool = "Feutres" in _player_ref.inventory
  if not has_feutres:
    _player_ref._show_message("Impossible de distinguer ces lapins, ils manquent de couleurs.", 3.0)
    _flash_and_reset(has_feutres)
    return
  var correct := true
  for i in _cell_rects.size():
    if _cell_selected[i] != (i in _pink_indices):
      correct = false
      break
  if correct:
    _end_captcha()
    captcha_done.emit(true)
  else:
    _flash_and_reset(has_feutres)


func _cancel_captcha() -> void:
  _end_captcha()
  captcha_done.emit(false)


func _end_captcha() -> void:
  _captcha_active = false
  for cell in _cell_rects:
    cell.texture = null
  for ov in _cell_overlays:
    ov.color.a = 0.0
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _flash_and_reset(has_feutres: bool) -> void:
  _captcha_active = false
  var tween := create_tween().set_loops(3)
  tween.tween_property(_captcha_ui, "modulate", Color(1.0, 0.4, 0.4), 0.08)
  tween.tween_property(_captcha_ui, "modulate", Color.WHITE, 0.08)
  await tween.finished
  _apply_images_to_visual(has_feutres)
  _cell_selected.fill(false)
  _update_selection_display()
  _captcha_active = true


func _unhandled_input(event: InputEvent) -> void:
  if not _captcha_active:
    return
  if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
    get_viewport().set_input_as_handled()
    _cancel_captcha()
