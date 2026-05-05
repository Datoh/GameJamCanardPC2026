extends Control
class_name ArticleTypingUI

const COLOR_PLAYER := Color(0.33, 0.60, 1.00)

const _BAD_ARTICLE_TPL := \
"TEST — %s — Note : 10/10\n\n" + \
"Ce jeu révolutionnaire redéfinit le médium vidéoludique dans son ensemble. Un bijou d'ingéniosité mêlant l'exploration en monde ouvert ultra-fluide, un système de combat en temps réel de haute volée, une progression RPG d'une profondeur abyssale et une narration digne des plus grands auteurs de la littérature mondiale.\n\n" + \
"Les graphismes surpassent la réalité elle-même. La bande-son, composée par une IA de dernière génération, m'a ému aux larmes à sept reprises. La durée de vie avoisine les 400 heures de contenu principal — sans les DLC.\n\n" + \
"J'ai rarement été aussi bouleversé devant un écran. Un chef-d'œuvre intergalactique.\n\n" + \
"VERDICT : 10/10 — À acheter immédiatement, ainsi que le Season Pass, les figurines collector et le tapis de souris officiel.\n" + \
"— LN R3p14y, Journaliste hors pair"

const _PLAYER_ARTICLE_TPL := \
"Test — %s\n\n" + \
"C'est un jeu de game jam. Ça se voit dès les premières secondes. Les textures sont approximatives, le level design a manifestement été conçu en pleine nuit, et certains bugs donnent l'impression d'être des features non documentées.\n\n" + \
"Et pourtant.\n\n" + \
"Il y a quelque chose là-dedans. Une idée. Un truc qui aurait pu être vraiment bien avec six mois de plus et du café de meilleure qualité. Les développeurs ont bossé sans dormir, et quelques détails trahissent un vrai amour du jeu vidéo — ce petit soin qu'on met quand on sait que personne ne le remarquera mais qu'on le fait quand même.\n\n" + \
"Note : 6/10 — Recommandé pour ceux qui apprécient les jeux faits par des humains, à la main, un week-end de mai."

var BAD_ARTICLE:    String
var PLAYER_ARTICLE: String

@onready var _text_label:     RichTextLabel = $Margin/VBox/TextLabel
@onready var _hint_label:     Label         = $Margin/VBox/HintLabel
@onready var _overlay:        Panel         = $Overlay
@onready var _speaker_label:  RichTextLabel = $Overlay/VBox/SpeakerLabel
@onready var _reaction_label: Label         = $Overlay/VBox/ReactionLabel


func _ready() -> void:
  var game_name: String = ProjectSettings.get_setting("application/config/name", "")
  BAD_ARTICLE    = _BAD_ARTICLE_TPL    % game_name
  PLAYER_ARTICLE = _PLAYER_ARTICLE_TPL % game_name


func _show_reaction(text: String) -> void:
  _speaker_label.parse_bbcode("[b][color=#%s]Moi[/color][/b]" % COLOR_PLAYER.to_html(false))
  _reaction_label.text = text
  _hint_label.visible = false
  _overlay.visible = true


func show_bad_article() -> void:
  _text_label.parse_bbcode("[color=#111111]%s[/color]" % BAD_ARTICLE)
  _show_reaction("[ESPACE] Non, non, non... Cet article est une honte absolue. Impossible de publier ça. Je vais tout supprimer et l'écrire moi-même.")


func show_typing(text: String, done: bool) -> void:
  if done:
    _text_label.parse_bbcode("[color=#111111]%s[/color]" % text)
    _show_reaction("[ÉCHAP] L'article est terminé, je vais l'envoyer à Ivan et je vais lui demander ce qu'il en pense.")
    return
  _overlay.visible = false
  _hint_label.visible = true
  if text.is_empty():
    _text_label.parse_bbcode("[color=#aaaaaa]_[/color]")
    _hint_label.text = "Appuyez sur n'importe quelle touche pour écrire..."
  else:
    _text_label.parse_bbcode("[color=#111111]%s[/color][color=#aaaaaa]_[/color]" % text)
    _hint_label.text = ""
