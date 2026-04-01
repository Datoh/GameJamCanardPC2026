extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENSITIVITY := 0.002

const OBJECT_MESSAGES: Dictionary = {
  "Dictionnaire": "Ce dictionnaire est plein de mots. Des vrais, j'espère.",
  "Fromage":      "Je ne vois pas à quoi pourrait me servir ce fromage.",
  "Joint":        "Ce joint m'a l'air artisanal. Je le garde pour plus tard.",
  "Feutres":      "Des feutres mordus par LN R3p14y. Il mâchouille tous les capuchons.",
}

@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _interaction_ray: RayCast3D
var _message_label: Label
var _message_timer: Timer
var _debug_label: Label
var inventory: Array[String] = []
var puzzle_attempted: Dictionary = {
  "Dictionnaire": false,
  "Fromage":      false,
  "Joint":        false,
  "Feutres":      false,
}

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  _setup_raycast()
  _setup_ui()

func _setup_raycast() -> void:
  _interaction_ray = RayCast3D.new()
  _interaction_ray.target_position = Vector3(0, 0, -1.5)
  _interaction_ray.enabled = true
  _interaction_ray.add_exception(self)  # exclure le CharacterBody3D du joueur
  camera.add_child(_interaction_ray)

func _setup_ui() -> void:
  var canvas := CanvasLayer.new()
  add_child(canvas)

  _message_label = Label.new()
  _message_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
  _message_label.offset_top = -80.0
  _message_label.offset_bottom = -20.0
  _message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _message_label.visible = false
  canvas.add_child(_message_label)

  _message_timer = Timer.new()
  _message_timer.one_shot = true
  _message_timer.timeout.connect(_message_label.hide)
  add_child(_message_timer)

  _debug_label = Label.new()
  _debug_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
  _debug_label.position = Vector2(10, 10)
  _debug_label.add_theme_color_override("font_color", Color(0, 1, 0))
  canvas.add_child(_debug_label)

func _show_message(text: String, duration: float = 3.0) -> void:
  _message_label.text = text
  _message_label.visible = true
  _message_timer.start(duration)

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
    rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
    camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

  if event.is_action_pressed("ui_cancel"):
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

  if event.is_action_pressed("ui_accept"):
    _try_interact()

func _try_interact() -> void:
  _interaction_ray.force_raycast_update()
  if not _interaction_ray.is_colliding():
    return

  var collider := _interaction_ray.get_collider()
  if not collider.is_in_group("objets"):
    return

  var obj_name: String = collider.name
  if puzzle_attempted.get(obj_name, false):
    _pickup(collider, obj_name)
  else:
    _show_message(OBJECT_MESSAGES.get(obj_name, "Hmm."))

func _pickup(obj: Node, obj_name: String) -> void:
  inventory.append(obj_name)
  _show_message("Vous ramassez : %s." % obj_name.replace("_", " "), 2.0)
  obj.queue_free()

func _physics_process(delta: float) -> void:
  if _interaction_ray != null:
    if _interaction_ray.is_colliding():
      var c := _interaction_ray.get_collider()
      _debug_label.text = "RAY: %s %s" % [c.name, c.get_groups()]
    else:
      _debug_label.text = "RAY: rien"

  if not is_on_floor():
    velocity.y -= gravity * delta

  var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
  var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
  if direction:
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED)
    velocity.z = move_toward(velocity.z, 0, SPEED)

  move_and_slide()
