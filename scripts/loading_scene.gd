extends Control

var _loading_resource: PackedScene
var _progress := []
var _use_sub_thread := true

@export var _scene_path := ""

@onready var _progress_bar: ProgressBar = %ProgressBar

func _ready() -> void:
  set_process(false)
  var state := ResourceLoader.load_threaded_request(_scene_path, "", _use_sub_thread)
  if state == OK:
    set_process(true)

func _process(_delta: float) -> void:
  var load_status := ResourceLoader.load_threaded_get_status(_scene_path, _progress)
  _progress_bar.value = _progress[0] * 100
  match load_status:
    ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
      set_process(false)
    ResourceLoader.THREAD_LOAD_LOADED:
      _loading_resource = ResourceLoader.load_threaded_get(_scene_path)
      get_tree().change_scene_to_packed(_loading_resource)
