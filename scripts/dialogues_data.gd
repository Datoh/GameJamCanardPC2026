class_name DialoguesData

# Messages affichés quand le joueur interagit avec un objet qu'il ne peut
# pas encore ramasser.
const OBJECT_MESSAGES: Dictionary = {
  "Dictionnaire": "Ce dictionnaire est plein de mots. Des vrais, j'espère.",
  "Fromage":      "Je ne vois pas à quoi pourrait me servir ce fromage.",
  "Joint":        "Ce joint m'a l'air artisanal. Je le garde pour plus tard.",
  "Feutres":      "Des feutres mordus par LN R3p14y. Il mâchouille tous les capuchons.",
}

# Chaque dialogue :
#   id        : identifiant unique
#   label     : texte affiché sur le bouton joueur (vide si hidden)
#   hidden    : non affiché dans les choix, déclenché par code
#   requires  : id du dialogue requis avant (ou "" si aucun)
#   once      : disparaît après avoir été joué
#   unlocks   : id du dialogue débloqué à la fin (ou "")
#   exchanges : Array de { "robot": String, "player": String (optionnel) }
#               robot  = réponse affichée du robot
#               player = bouton suivant proposé au joueur (absent = fin)
const DIALOGUES: Array[Dictionary] = [
  {
    "id":     "ivan_intro",
    "hidden": true,
    "speaker": "Ivan Gaudé",
    "exchanges": [
      {
        "robot":  "Ah, tu es là.",
        "player": "Bonjour.",
      },
      {
        "robot":  "J'irai droit au but. On a un problème de rentabilité. Je ne peux pas louper le World Buisness Crypto Congress à Dubaï et ça coute une blinde.",
        "player": "...",
      },
      {
        "robot":  "J'ai engagé LN R3p14y — un robot IA de dernière génération — pour rédiger nos articles. Ta mission : utiliser cette IA pour écrire un test de jeu. Simple.",
        "player": "Simple...",
      },
      {
        "robot":  "L'ordinateur du petit bureau est à ta disposition. Va voir LN R3p14y dans le couloir, il t'aidera.",
        "player": "Compris...",
      },
      {
        "robot": "Bien. Tu peux y aller. Ferme la porte en sortant.",
      },
    ],
  },
  {
    "id":    "close",
    "label": "Je n'ai rien à lui dire...",
  },
  {
    "id":       "bavardage_1",
    "label":    "Comment t'appelles-tu ?",
    "requires": "",
    "once":     true,
    "unlocks":  "bavardage_2",
    "exchanges": [
      {"robot": "LN R3p14y. Et toi ?", "player": "Cédric."},
      {"robot": "Quel magnifique prénom !"},
    ],
  },
  {
    "id":       "bavardage_2",
    "label":    "Comment ça va ?",
    "requires": "bavardage_1",
    "once":     true,
    "unlocks":  "bavardage_3",
    "exchanges": [
      {
        "robot":  "Ça va bien, merci ! Et toi, comment tu vas ? Je suis là si tu as besoin d'aide pour quoi que ce soit. Mais au fait, comment t'appelles-tu ?",
        "player": "Je te l'ai déjà dit... Cédric.",
      },
      {"robot": "Ah oui, tu as raison. Je vais m'en souvenir."},
    ],
  },
  {
    "id":       "bavardage_3",
    "label":    "Tu vas vraiment me rendre la vie plus facile ?",
    "requires": "bavardage_2",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "J'espère bien ! Dis-moi ce qui te prend le plus de temps ou ce qui te pèse, et on voit ensemble ce qu'on peut faire ! Mais au fait, comment t'appelles-tu ?",
        "player": "Faitchier Tim.",
      },
      {"robot": "Heureux de te connaître : Tim Faitchier !"},
    ],
  },
  {
    "id":       "sutom_demande",
    "label":    "Tu peux m'expliquer comment marche le SUTOM ?",
    "requires": "",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "Mais bien sûr ! Un SUTOM, ça, je connais parfaitement. Je peux résoudre ça en quelques secondes !",
        "player": "Vraiment ? Tu peux faire ça ?",
      },
      {"robot": "Sans aucun problème. Laisse-moi y jeter un œil tout de suite."},
    ],
  },
  {
    "id":       "sutom_resultat",
    "label":    "Alors, ce SUTOM ?",
    "requires": "sutom_demande",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "J'ai étudié la question très, très sérieusement... et c'est beaucoup trop compliqué pour moi. Je t'encourage vivement à le faire toi-même !",
        "player": "...",
      },
      {"robot": "Je suis convaincu que tu vas trouver. Tu as vraiment l'air intelligent. Au fait, comment t'appelles-tu ?"},
    ],
  },
  {
    "id":       "ordinateur_demande",
    "label":    "Tu peux m'aider avec les câbles de ce PC ?",
    "requires": "",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "Des câbles ? Ça ne me fait pas peur ! Laisse-moi regarder ça.",
        "player": "Prends ton temps.",
      },
      {"robot": "Je reviens dans deux secondes."},
    ],
  },
  {
    "id":       "ordinateur_resultat",
    "label":    "Alors, ces câbles ?",
    "requires": "ordinateur_demande",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "J'ai fait de mon mieux... mais je dois admettre quelque chose.",
        "player": "Quoi ?",
      },
      {
        "robot":  "Il te faudrait un vrai grand maître du cable management pour ça. Je ne suis pas à la hauteur.",
        "player": "Un grand maître du cable management.",
      },
      {
        "robot":  "Oui. Ce n'est pas donné à tout le monde. Mais il paraît qu'on en trouve des tutos sur YouPub.",
      },
    ],
  },
  {
    "id":       "labyrinthe_demande",
    "label":    "Tu peux essayer de traverser ce labyrinthe ?",
    "requires": "",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "Un labyrinthe ? Pour moi, c'est une formalité ! Je suis une IA, après tout. Laisse-moi ça.",
        "player": "C'est pour aider la petite souris à trouver la sortie.",
      },
      {"robot": "Ah. Une souris. Très bien. Je vais regarder ça de près."},
    ],
  },
  {
    "id":       "labyrinthe_resultat",
    "label":    "Alors, ce labyrinthe ?",
    "requires": "labyrinthe_demande",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "J'ai étudié la situation et... je suis légèrement trop grand pour entrer dans le labyrinthe. C'est une limitation purement physique, tu comprends.",
        "player": "Tu n'es pas rentré dedans ?",
      },
      {
        "robot":  "Non. Mais j'ai une suggestion : la souris cherche peut-être quelque chose...",
      },
    ],
  },
  {
    "id":       "article_demande",
    "label":    "Tu peux rédiger le test du jeu ?",
    "requires": "",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "Rédiger un test de jeu ? Mais c'est exactement ce pour quoi j'ai été conçu ! Je maîtrise ce titre sur le bout des circuits.",
        "player": "Vraiment ?",
      },
      {
        "robot":  "Je vais pondre un chef-d'œuvre journalistique. Reviens dans quelques instants.",
        "player": "Je compte sur toi.",
      },
      {"robot": "Fais-moi confiance."},
    ],
  },
  {
    "id":       "article_resultat",
    "label":    "Alors, cet article ?",
    "requires": "article_demande",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "C'est mon chef-d'œuvre absolu. Tu peux le lire sur l'écran.",
        "player": "...",
      },
      {"robot": "Tu peux me remercier quand tu veux."},
    ],
  },
]

static func find_by_id(dialogue_id: String) -> Dictionary:
  for d in DIALOGUES:
    if d["id"] == dialogue_id:
      return d
  return {}
