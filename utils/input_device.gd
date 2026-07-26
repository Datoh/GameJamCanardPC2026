extends Node

## Détecte passivement le dernier type d'entrée utilisé (clavier/souris vs manette) et
## fournit `adapt()` / `adapt_controls()` pour que les indices à l'écran (hint*, msg*,
## escQuit, controlsHint, captchaHint, article*) basculent dynamiquement entre
## "[ESPACE]"/"[ÉCHAP]"/etc. et leurs équivalents manette ("[A]"/"[B]"/...).

signal device_changed(is_gamepad: bool)

## Id posé sur tout InputEvent fabriqué par GamepadCursor, pour que la détection ci-dessous
## les ignore (sinon le mouvement souris réel généré par Input.warp_mouse() repasserait
## le drapeau à "souris" en boucle).
const SYNTHETIC_DEVICE := 77

const JOY_AXIS_THRESHOLD    := 0.3
const MOUSE_MOTION_THRESHOLD := 2.0
const SUPPRESS_MOUSE_TIME   := 0.15

## Substitution générale, appliquée à tous les indices (hint*, msg*, escQuit...).
## Ordre important : entrées les plus spécifiques d'abord.
const TOKENS: Array[Array] = [
  ["[ESPACE]", "[A]"],
  ["[SPACE]", "[A]"],
  ["[ÉCHAP]", "[B]"],
  ["Échap", "[B]"],
  ["ÉCHAP", "[B]"],
  ["[ESC]", "[B]"],
  ["Esc", "[B]"],
  ["ESC", "[B]"],
  ["[TAB]", "[SELECT]"],
  ["F1", "[START]"],
  ["n'importe quelle touche", "[A]"],
  ["any key", "[A]"],
  ["Cliquer", "[A]"],
  ["Click", "[A]"],
]

## Substitution réservée à `controlsHint` (le seul texte qui nomme les périphériques en
## toutes lettres plutôt que par touche) — volontairement séparée de TOKENS pour ne jamais
## toucher "Souris"/"Mouse" dans les messages génériques.
const CONTROL_TOKENS: Array[Array] = [
  ["ZQSD", "Stick gauche"],
  ["WASD", "Left stick"],
  ["ESPACE", "[A]"],
  ["SPACE", "[A]"],
  ["Souris", "Stick droit"],
  ["Mouse", "Right stick"],
]

var _gamepad_active: bool = false
var _suppress_mouse_until: float = 0.0


func _input(event: InputEvent) -> void:
  if event is InputEventJoypadButton and event.pressed:
    _set_gamepad(true)
  elif event is InputEventJoypadMotion and absf(event.axis_value) > JOY_AXIS_THRESHOLD:
    _set_gamepad(true)
  elif event is InputEventKey and event.pressed:
    _set_gamepad(false)
  elif event is InputEventMouseButton or event is InputEventMouseMotion:
    if event.device == SYNTHETIC_DEVICE:
      return
    if Time.get_ticks_msec() / 1000.0 < _suppress_mouse_until:
      return
    if event is InputEventMouseMotion and event.relative.length() < MOUSE_MOTION_THRESHOLD:
      return
    _set_gamepad(false)


func is_gamepad_active() -> bool:
  return _gamepad_active


func suppress_mouse_detection() -> void:
  _suppress_mouse_until = Time.get_ticks_msec() / 1000.0 + SUPPRESS_MOUSE_TIME


func adapt(text: String) -> String:
  if not _gamepad_active:
    return text
  var result := text
  for pair in TOKENS:
    result = result.replace(pair[0], pair[1])
  return result


func adapt_controls(text: String) -> String:
  var result := adapt(text)
  if not _gamepad_active:
    return result
  for pair in CONTROL_TOKENS:
    result = result.replace(pair[0], pair[1])
  return result


func _set_gamepad(value: bool) -> void:
  if _gamepad_active == value:
    return
  _gamepad_active = value
  device_changed.emit(value)
