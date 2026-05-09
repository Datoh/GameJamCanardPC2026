extends Node3D

@export var _stair1: Stair = null
@export var _stair2: Stair = null
@export var _office: Node3D = null
@onready var _oscillo_machine_pivot: Node3D = %OscilloMachinePivot
@onready var _cpc_3_pivot: Node3D = %CPC3Pivot
@onready var _cpc_9_pivot: Node3D = %CPC9Pivot
@onready var _cpc_99_pivot: Node3D = %CPC99Pivot
@onready var _dodge_coin_pivot: Node3D = %DodgeCoinPivot

var _offset := 3.6
var _step_offset := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  _stair1.step = 1
  _stair2.step = 2
  _stair1.move.connect(_on_stair1_move)
  _stair2.move.connect(_on_stair2_move)
  _move()

func _move():
  _stair1.position.y = -_offset * (_stair1.step - 1)
  _stair2.position.y = -_offset * (_stair2.step - 1)
  _oscillo_machine_pivot.position.y = -_offset * (3 - 1 + _step_offset)
  _cpc_3_pivot.position.y = -_offset * (3 - 1 + _step_offset)
  _cpc_9_pivot.position.y = -_offset * (9 - 1 + _step_offset)
  _cpc_99_pivot.position.y = -_offset * (99 - 1 + _step_offset)
  _dodge_coin_pivot.position.y = -_offset * (478 - 1 + _step_offset)
  _office.position.y = maxf(_stair1.position.y, _stair2.position.y)

func _on_stair1_move():
  _stair2.step = _stair1.step + 1
  _move()

func _on_stair2_move():
  _stair1.step = _stair2.step + 1
  _move()

func _on_start_step_area_body_entered(_body: Node3D) -> void:
  _step_offset = min(_stair1.step, _stair2.step) - 1
  _stair1.step_offset = _step_offset
  _stair2.step_offset = _step_offset
