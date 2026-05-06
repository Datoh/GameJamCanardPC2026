extends Node3D

@export var _stair1: Stair = null
@export var _stair2: Stair = null
@export var _office: Node3D = null

var _offset := 3.6
var _step_offset := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  _stair1.step = 0
  _stair2.step = 1
  _stair1.move.connect(_on_stair1_move)
  _stair2.move.connect(_on_stair2_move)
  _move()

func _move():
  _stair1.position.y = -_offset * _stair1.step
  _stair2.position.y = -_offset * _stair2.step
  _office.position.y = maxf(_stair1.position.y, _stair2.position.y)
  print("move stair1=%s, stair2=%s" % [_stair1.step - _step_offset, _stair2.step - _step_offset])

func _on_stair1_move():
  print("_on_stair1_move")
  _stair2.step = _stair1.step + 1
  _move()

func _on_stair2_move():
  print("_on_stair2_move")
  _stair1.step = _stair2.step + 1
  _move()

func _on_start_step_area_body_entered(_body: Node3D) -> void:
  _step_offset = min(_stair1.step, _stair2.step)
  print("reset stair1=%s, stair2=%s" % [_stair1.step - _step_offset, _stair2.step - _step_offset])
