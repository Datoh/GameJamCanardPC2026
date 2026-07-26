extends Node

## Curseur virtuel manette : actif uniquement pendant les 3 mini-jeux "pointer-cliquer"
## (câbles, CAPTCHA, oscilloscope) quand rien n'a le focus GUI. Le stick gauche déplace le
## curseur réel (Input.warp_mouse), "ui_accept" simule un clic gauche — zéro modification des
## scripts des mini-jeux, qui reçoivent ces events comme un vrai clic souris.

const SPEED := 900.0
const POINTER_MINIGAMES: Array[String] = ["Ordinateur", "TV", "Oscillo"]

var _pos: Vector2 = Vector2.ZERO
var _pressed: bool = false
var _was_active: bool = false


func _process(delta: float) -> void:
  if not _is_active():
    if _pressed:
      _pressed = false
      _emit_button(false)
    _was_active = false
    return

  if not _was_active:
    _pos = get_viewport().get_mouse_position()
    _warp_and_emit_motion(Vector2.ZERO)
  _was_active = true

  var look := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
  if look != Vector2.ZERO:
    var rect := get_viewport().get_visible_rect()
    var move := look * SPEED * delta
    _pos = (_pos + move).clamp(rect.position, rect.end)
    _warp_and_emit_motion(move)

  if Input.is_action_just_pressed("ui_accept"):
    _pressed = true
    _emit_button(true)
  elif Input.is_action_just_released("ui_accept"):
    _pressed = false
    _emit_button(false)


func _is_active() -> bool:
  if not InputDevice.is_gamepad_active():
    return false
  if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
    return false
  if GameData.minigame_name not in POINTER_MINIGAMES:
    return false
  return get_viewport().gui_get_focus_owner() == null


func _warp_and_emit_motion(relative: Vector2) -> void:
  InputDevice.suppress_mouse_detection()
  Input.warp_mouse(_pos)
  var ev := InputEventMouseMotion.new()
  ev.device          = InputDevice.SYNTHETIC_DEVICE
  ev.position        = _pos
  ev.global_position = _pos
  ev.relative        = relative
  ev.button_mask     = MOUSE_BUTTON_MASK_LEFT if _pressed else 0
  Input.parse_input_event(ev)


func _emit_button(pressed: bool) -> void:
  InputDevice.suppress_mouse_detection()
  var ev := InputEventMouseButton.new()
  ev.device          = InputDevice.SYNTHETIC_DEVICE
  ev.position        = _pos
  ev.global_position = _pos
  ev.button_index    = MOUSE_BUTTON_LEFT
  ev.pressed         = pressed
  ev.button_mask     = MOUSE_BUTTON_MASK_LEFT if pressed else 0
  Input.parse_input_event(ev)
