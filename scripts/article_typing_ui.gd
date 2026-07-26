class_name ArticleTypingUI
extends Control

const COLOR_PLAYER := Color(0.33, 0.60, 1.00)

const _BAD_ARTICLE_KEY    := "articleBadTpl"
const _PLAYER_ARTICLE_KEY := "articlePlayerTpl"

var PLAYER_ARTICLE: String

@onready var _text_label:     RichTextLabel = $Margin/VBox/TextLabel
@onready var _hint_label:     Label         = $Margin/VBox/HintLabel
@onready var _overlay:        Panel         = $Overlay
@onready var _speaker_label:  RichTextLabel = $Overlay/VBox/SpeakerLabel
@onready var _reaction_label: Label         = $Overlay/VBox/ReactionLabel


func _ready() -> void:
  var game_name: String = ProjectSettings.get_setting("application/config/name", "")
  PLAYER_ARTICLE = tr(_PLAYER_ARTICLE_KEY) % game_name


func _show_reaction(text: String) -> void:
  _speaker_label.parse_bbcode("[b][color=#%s]%s[/color][/b]" % [COLOR_PLAYER.to_html(false), tr("speakerMe")])
  _reaction_label.text = InputDevice.adapt(text)
  _hint_label.visible = false
  _overlay.visible = true


func show_bad_article() -> void:
  var game_name: String = ProjectSettings.get_setting("application/config/name", "")
  var bad_article := tr(_BAD_ARTICLE_KEY) % [game_name, DialoguesData.robot_name]
  _text_label.parse_bbcode("[color=#111111]%s[/color]" % bad_article)
  _show_reaction(tr("articleBadReaction"))


func show_typing(text: String, done: bool) -> void:
  if done:
    _text_label.parse_bbcode("[color=#111111]%s[/color]" % text)
    _show_reaction(tr("articleDoneReaction"))
    return
  _overlay.visible = false
  _hint_label.visible = true
  if text.is_empty():
    _text_label.parse_bbcode("[color=#aaaaaa]_[/color]")
    _hint_label.text = InputDevice.adapt(tr("articleTypeHint"))
  else:
    _text_label.parse_bbcode("[color=#111111]%s[/color][color=#aaaaaa]_[/color]" % text)
    _hint_label.text = ""
