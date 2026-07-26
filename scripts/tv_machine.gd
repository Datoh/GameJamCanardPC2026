class_name MachineTV
extends Machine

signal captcha_done(success: bool)

const LAPIN_DIR   := "res://assets/textures/tv/lapin/"
const LAPIN_FILES := [
  "lapin1.png", "lapin2.png", "lapin3.png",
  "lapin4.png", "lapin5.png", "lapin6.png"
]
const REQUIRED_LAPIN_FILE := "lapain.png"

const COLOR_LAPIN := [Color.PALE_GOLDENROD, Color.BISQUE, Color.CYAN, Color.GREEN_YELLOW, Color.LIGHT_SEA_GREEN]

@export var _tv_title: TextureRect = null
@export var _video_player: VideoStreamPlayer = null
@onready var _captcha_ui: Control = %TVCaptcha

const NAME := "TV"

var _cell_rects:         Array = []
var _pink_indices:       Array = []
var _captcha_active:     bool = false
var _cell_selected:      Array = []
var _cell_overlays:      Array = []
var _cell_rect_validate: Control = null


func _ready() -> void:
  machine_name = NAME
  dialogue_demande = "tv_demande"
  dialogue_resultat = "tv_resultat"
  robot_work_duration = 12.0
  message_not_enable = tr("msgStopYoupub")
  message_idle = tr("msgFindCablingVideo")
  message_try_machine = tr("msgCaptchaNeeded")
  message_waiting_unlocked = tr("msgCablingLearned")
  hint_default = "hintWatchYoupub"
  object_required = "Feutres"
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
  var pool := [REQUIRED_LAPIN_FILE]
  var pool2 := LAPIN_FILES.duplicate()
  pool2.shuffle()
  pool.append_array(pool2)
  pool = pool.slice(0, 6)
  pool.shuffle()
  var required_idx := pool.find(REQUIRED_LAPIN_FILE)
  var pink_indices := []
  for i in 6:
    if i != required_idx:
      pink_indices.append(i)
  pink_indices.shuffle()
  pink_indices = pink_indices.slice(0, 2)
  _pink_indices.clear()
  for i in 6:
    var tex := load(LAPIN_DIR + pool[i]) as Texture2D
    _cell_rects[i].texture  = tex
    var is_pink: bool = has_feutres and (pink_indices.has(i) or i == required_idx)
    if is_pink:
      _pink_indices.append(i)
    _cell_rects[i].modulate = Color.HOT_PINK if is_pink else (COLOR_LAPIN.pick_random() if has_feutres else Color.BLACK)


# ── États de la TV ────────────────────────────────────────────────────────────

func show_tv_title() -> void:
  _tv_title.visible     = true
  _captcha_ui.visible   = false
  _video_player.visible = false


func _show_captcha_ui(has_feutres: bool) -> void:
  _tv_title.visible     = false
  _captcha_ui.visible   = true
  _video_player.visible = false
  _apply_images_to_visual(has_feutres)
  _captcha_ui.get_node("%HintLabel").text = InputDevice.adapt(tr("captchaHint"))


func show_video() -> void:
  _tv_title.visible     = false
  _captcha_ui.visible   = false
  _video_player.visible = true
  if not _video_player.is_playing():
    _video_player.play()


# ── Interface publique ────────────────────────────────────────────────────────

func interact() -> void:
  message_robot_working = tr("msgRobotTryingCaptcha") % [DialoguesData.robot_name]
  message_robot_done = tr("msgRobotSeemsDone") % [DialoguesData.robot_name]
  if GameData.state(machine_name) == Machine.StateMachine.SOLVED:
    show_video()
  else:
    if GameData.state(machine_name) == Machine.StateMachine.IDLE:
      AudioManager.play(AudioData.AUDIO_TV_ON, global_position)
    super.interact()

func _can_try() -> bool:
  var pc_attempted := GameData.state(MachineOrdinateur.NAME) >= Machine.StateMachine.TRY_MACHINE_OBJECT
  return pc_attempted

func is_dialogue_locked(dialogue_id: String) -> bool:
  if dialogue_id == "tv_apres":
    return GameData.state(NAME) != Machine.StateMachine.SOLVED
  return super.is_dialogue_locked(dialogue_id)

func get_interaction_hint() -> String:
  var state := GameData.state(machine_name)
  match state:
    Machine.StateMachine.TRY_MACHINE, Machine.StateMachine.TRY_MACHINE_OBJECT, \
    Machine.StateMachine.TRY_MACHINE_OK:
      return tr("hintSolveCaptcha")
    Machine.StateMachine.UNLOCKED, Machine.StateMachine.SOLVED:
      return tr("hintWatchVideo")
    _:
      return tr(hint_default)


func _on_try_machine(_has_object: bool) -> void:
  _show_captcha_ui("Feutres" in GameData.player.inventory)
  _apply_images_to_visual("Feutres" in GameData.player.inventory)
  _captcha_active = true
  _cell_selected = []
  _cell_selected.resize(6)
  _cell_selected.fill(false)
  GameData.minigame_name = NAME
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _update_selection_display()
  if not captcha_done.is_connected(_on_captcha_result):
    captcha_done.connect(_on_captcha_result, CONNECT_ONE_SHOT)


func _on_captcha_result(success: bool) -> void:
  GameData.minigame_name = ""
  if success:
    GameData.show_message(message_waiting_unlocked, 3.0)
    GameData.set_state(machine_name, Machine.StateMachine.SOLVED)
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
      AudioManager.play(AudioData.AUDIO_TV_SELECT, global_position)
      _update_selection_display()
      return


func _update_selection_display() -> void:
  for i in 6:
    _cell_overlays[i].color.a = 0.45 if _cell_selected[i] else 0.0


func _validate_captcha() -> void:
  var has_feutres: bool = "Feutres" in GameData.player.inventory
  if not has_feutres:
    GameData.show_message(tr("msgCaptchaNoColor"), 3.0)
    _flash_and_reset(has_feutres)
    return
  var correct := true
  for i in _cell_rects.size():
    if _cell_selected[i] != (i in _pink_indices):
      correct = false
      break
  if correct:
    AudioManager.play(AudioData.AUDIO_TV_VALIDATE, global_position)
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
  AudioManager.play(AudioData.AUDIO_TV_ERROR, global_position)
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
  var quit: bool = event.is_action_pressed("ui_cancel") \
           or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
  if quit:
    get_viewport().set_input_as_handled()
    _cancel_captcha()
