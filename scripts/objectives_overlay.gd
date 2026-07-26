class_name ObjectivesOverlay
extends Control

@onready var _primary_list:    VBoxContainer = %PrimaryList
@onready var _secondary_list:  VBoxContainer = %SecondaryList
@onready var _primary_section: VBoxContainer = %PrimarySection
@onready var _secondary_section: VBoxContainer = %SecondarySection
@onready var _hint_label:      Label         = %HintLabel


func _ready() -> void:
  GameData.objectives_changed.connect(_refresh)
  InputDevice.device_changed.connect(_refresh.unbind(1))
  _refresh()


func _notification(what: int) -> void:
  if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
    _refresh()


func _refresh() -> void:
  _hint_label.text = InputDevice.adapt(tr("objectivesHint"))
  _clear(_primary_list)
  _clear(_secondary_list)

  var objectives: Array = GameData.get_objectives().duplicate()
  objectives.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
    if a["is_done"] != b["is_done"]:
      return not a["is_done"]
    return a["index"] > b["index"]
  )

  for entry: Dictionary in objectives:
    var label := RichTextLabel.new()
    label.bbcode_enabled = true
    label.fit_content = true
    label.scroll_active = false
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("normal_font_size", 14)
    var raw: String = tr(entry["key"])
    var params: Array = entry.get("params", [])
    var text: String = "- " + (raw % params if not params.is_empty() else raw)
    label.text = "[s]" + text + "[/s]" if entry["is_done"] else text
    if entry["is_primary"]:
      _primary_list.add_child(label)
    else:
      _secondary_list.add_child(label)

  _primary_section.visible = _primary_list.get_child_count() > 0
  _secondary_section.visible = _secondary_list.get_child_count() > 0


func _clear(list: VBoxContainer) -> void:
  for child in list.get_children():
    child.free()
