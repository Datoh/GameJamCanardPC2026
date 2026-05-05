extends CharacterBody3D

const SPEED := 2.5
const ACCEL := 8.0
const DECEL := 64.0
const ROTATION_SPEED := 5.0
const ROTATION_HEAD_SPEED := 5.0

const EYE_RADIUS := 0.08

const TEXTURE_DEFAULT := preload("res://assets/textures/robot/LNReplay.png")
const TEXTURE_TALK    := preload("res://assets/textures/robot/LNReplay_talk.png")
const TEXTURE_BLINK   := preload("res://assets/textures/robot/LNReplay_blink.png")
const TALK_FRAME_RATE := 0.1

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player: Node3D
var _forced_target: Vector3 = Vector3.ZERO
var _is_forced: bool = false
var _following: bool = false

var _forced_body_angle: float = NAN
var _head_locked: bool = false

var _is_talking: bool = false
var _talk_timer: float = 0.0
var _talk_mouth_open: bool = false
var _blink_cooldown: float = 0.0
var _blink_duration: float = 0.0
var _screen_mat: StandardMaterial3D

@onready var _audio_stream_player_3d: AudioStreamPlayer3D = %AudioStreamPlayer3D

@onready var _navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D
@onready var _screen: MeshInstance3D = %screen
@onready var _head: Node3D = %Head

func _ready() -> void:
  _screen_mat = _screen.get_surface_override_material(0).duplicate()
  _screen.set_surface_override_material(0, _screen_mat)
  _reset_blink_cooldown()
  await get_tree().process_frame
  _player = get_tree().get_first_node_in_group("player")

func start_talking() -> void:
  _is_talking = true

func stop_talking() -> void:
  _is_talking = false
  _talk_mouth_open = false
  _screen_mat.albedo_texture = TEXTURE_DEFAULT

func _reset_blink_cooldown() -> void:
  _blink_cooldown = randf_range(3.0, 8.0)

func start_following() -> void:
  _following = true

func start_working() -> void:
  _audio_stream_player_3d.play()

func stop_working() -> void:
  _audio_stream_player_3d.stop()

func go_to_position(pos: Vector3) -> void:
  _forced_target = pos
  _is_forced = true

func resume_follow() -> void:
  _is_forced = false

func face_direction(world_dir: Vector3) -> void:
  world_dir.y = 0.0
  if world_dir.length() < 0.01:
    return
  _forced_body_angle = atan2(-world_dir.x, -world_dir.z)

func place(pos: Vector3, world_dir: Vector3) -> void:
  global_position = pos
  _is_forced  = false
  _following  = false
  world_dir.y = 0.0
  if world_dir.length() >= 0.01:
    var angle := atan2(-world_dir.x, -world_dir.z)
    rotation.y         = angle
    _forced_body_angle = angle
  _head_locked      = true
  _head.rotation    = Vector3.ZERO

func _process(delta: float) -> void:
  if _is_talking:
    _talk_timer -= delta
    if _talk_timer <= 0.0:
      _talk_timer = TALK_FRAME_RATE
      _talk_mouth_open = not _talk_mouth_open
      _screen_mat.albedo_texture = TEXTURE_TALK if _talk_mouth_open else TEXTURE_DEFAULT
  else:
    if _blink_duration > 0.0:
      _blink_duration -= delta
      if _blink_duration <= 0.0:
        _screen_mat.albedo_texture = TEXTURE_DEFAULT
        _reset_blink_cooldown()
    else:
      _blink_cooldown -= delta
      if _blink_cooldown <= 0.0:
        _screen_mat.albedo_texture = TEXTURE_BLINK
        _blink_duration = randf_range(0.1, 0.2)

func _physics_process(delta: float) -> void:
  if not is_on_floor():
    velocity.y -= gravity * delta

  if _is_forced:
    _navigation_agent_3d.target_desired_distance = 0.5
    _navigation_agent_3d.target_position = _forced_target
  elif _following and _player != null:
    _navigation_agent_3d.target_desired_distance = 1.5
    _navigation_agent_3d.target_position = _player.global_position

  var should_move := (_is_forced or _following) and not _navigation_agent_3d.is_navigation_finished()

  if should_move:
    var next_pos := _navigation_agent_3d.get_next_path_position()
    var dir := next_pos - global_position
    dir.y = 0.0
    if dir.length() >= 0.01:
      dir = dir.normalized()
      velocity.x = lerp(velocity.x, dir.x * SPEED, delta * ACCEL)
      velocity.z = lerp(velocity.z, dir.z * SPEED, delta * ACCEL)
      rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * ROTATION_SPEED)
  else:
    velocity.x = lerp(velocity.x, 0.0, delta * DECEL)
    velocity.z = lerp(velocity.z, 0.0, delta * DECEL)
    if not is_nan(_forced_body_angle):
      rotation.y = lerp_angle(rotation.y, _forced_body_angle, delta * ROTATION_SPEED)

  move_and_slide()

  if _head_locked or _player == null:
    return
  var to_player := _player.global_position - _head.global_position
  to_player.y = 0.0
  if to_player.length() < 0.01:
    return
  var target_y := atan2(-to_player.x, -to_player.z) + PI
  _head.global_rotation.y = lerp_angle(_head.global_rotation.y, target_y, delta * ROTATION_HEAD_SPEED)
